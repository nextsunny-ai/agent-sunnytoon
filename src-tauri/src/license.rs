// JWT 라이선스 검증·관리 (= Tauri Rust 측)
//
// 흐름:
// 1. 앱 시작 → license.json read → JWT 만료 여부 검증
// 2. 만료/없음 → Vercel API `/api/license/check` 호출 (작가 인증 후)
// 3. 새 JWT 받음 → license.json 저장 (~/.sunny-story-maker/license.json)
// 4. 7일 후 = 자동 재검증 (앱 시작 시)

use chrono::Utc;
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LicenseClaims {
    pub user_id: String,
    pub email: String,
    pub plan: String,
    pub status: String,
    pub iss: Option<String>,
    pub sub: Option<String>,
    pub iat: Option<i64>,
    pub exp: Option<i64>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LicenseStorage {
    pub token: String,
    pub plan: String,
    pub status: String,
    pub valid_until: Option<String>,
    pub issued_at: String,
    pub expires_at: String,
}

#[derive(Debug, thiserror::Error)]
pub enum LicenseError {
    #[error("license file not found")]
    NotFound,
    #[error("license expired")]
    Expired,
    #[error("license invalid: {0}")]
    Invalid(String),
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),
}

/// 라이선스 저장 경로 = `~/.sunny-story-maker/license.json`
pub fn license_path() -> Option<PathBuf> {
    let mut p = dirs::home_dir()?;
    p.push(".sunny-story-maker");
    Some(p)
}

pub fn license_file() -> Option<PathBuf> {
    let mut p = license_path()?;
    p.push("license.json");
    Some(p)
}

/// 옛 라이선스 read
pub fn load() -> Result<LicenseStorage, LicenseError> {
    let path = license_file().ok_or(LicenseError::NotFound)?;
    if !path.exists() {
        return Err(LicenseError::NotFound);
    }
    let data = std::fs::read_to_string(&path)?;
    let storage: LicenseStorage = serde_json::from_str(&data)?;
    Ok(storage)
}

/// 라이선스 저장
pub fn save(storage: &LicenseStorage) -> Result<(), LicenseError> {
    let dir = license_path().ok_or(LicenseError::NotFound)?;
    std::fs::create_dir_all(&dir)?;
    let path = license_file().ok_or(LicenseError::NotFound)?;
    let data = serde_json::to_string_pretty(storage)?;
    std::fs::write(&path, data)?;
    Ok(())
}

/// 라이선스 삭제 (= 로그아웃)
pub fn clear() -> Result<(), LicenseError> {
    if let Some(path) = license_file() {
        if path.exists() {
            std::fs::remove_file(&path)?;
        }
    }
    Ok(())
}

/// JWT decode (= 서명 검증 X — 서버에서만 검증. 클라이언트는 만료만 체크).
/// 클라이언트는 secret 보유 X = 서명 검증 X. 만료 검증 + claims read만.
///
/// ★ v1.1 (2026-05-26) = CRITICAL-3 정정:
/// 현재 = 라이선스 시스템 = 비활성 (= BYOK 모델 = 모두 free 동등) = is_valid() 호출 0건.
/// 결제 활성화 시점 = 본 함수 = decode_with_pubkey() (= RS256 공개키 검증) 으로 정정 의무.
/// 또는 = 매 호출 시 = 서버 /api/license/check 재검증 의무화 (= 클라이언트 위조 차단).
pub fn decode_unverified(token: &str) -> Result<LicenseClaims, LicenseError> {
    // 서명 검증 안 함 (= 더미 secret + insecure mode)
    let mut validation = Validation::new(Algorithm::HS256);
    validation.insecure_disable_signature_validation();
    validation.validate_exp = false; // exp는 별도 체크
    validation.required_spec_claims.clear();

    let dummy_key = DecodingKey::from_secret(b"dummy");
    let token_data = decode::<LicenseClaims>(token, &dummy_key, &validation)
        .map_err(|e| LicenseError::Invalid(e.to_string()))?;
    Ok(token_data.claims)
}

/// 라이선스 만료 여부 (= claims.exp vs 현재 시각)
pub fn is_expired(claims: &LicenseClaims) -> bool {
    let now = Utc::now().timestamp();
    match claims.exp {
        Some(exp) => exp < now,
        None => true, // exp 없으면 = 만료로 간주
    }
}

/// 라이선스 유효성 종합 검증
pub fn is_valid(storage: &LicenseStorage) -> bool {
    // 1) status 검증
    if storage.status != "active" {
        return false;
    }
    // 2) plan 검증
    if storage.plan == "banned" {
        return false;
    }
    // 3) JWT 만료 검증
    match decode_unverified(&storage.token) {
        Ok(claims) => !is_expired(&claims),
        Err(_) => false,
    }
}

// ============================================================
// ★ v1.1 (2026-05-26) = JWT RS256 서명 검증 path 박힘 (= 미래 활성화용)
// ============================================================
//
// 결제 활성화 시점에 = 본 함수 사용 = decode_unverified 대체 의무.
// 사용 path:
//   1. Vercel API `/api/license/check` = 서버 = RS256 private key로 sign
//   2. 클라이언트 (= 본 Tauri 앱) = public key 박혀있음 (= 컴파일 시 박힘)
//   3. 본 함수 = JWT 서명 검증 = 위조 차단
//
// 박힘 path:
//   PUBLIC_KEY_PEM = include_str!("../keys/license_public.pem");
//   let key = DecodingKey::from_rsa_pem(PUBLIC_KEY_PEM.as_bytes())?;

pub fn decode_with_pubkey(token: &str, pubkey_pem: &str) -> Result<LicenseClaims, LicenseError> {
    use jsonwebtoken::Algorithm;
    let key = DecodingKey::from_rsa_pem(pubkey_pem.as_bytes())
        .map_err(|e| LicenseError::Invalid(format!("invalid pubkey: {}", e)))?;
    let mut validation = Validation::new(Algorithm::RS256);
    validation.validate_exp = true;
    validation.required_spec_claims.clear();
    validation.required_spec_claims.insert("exp".to_string());

    let token_data = decode::<LicenseClaims>(token, &key, &validation)
        .map_err(|e| LicenseError::Invalid(e.to_string()))?;
    Ok(token_data.claims)
}

/// ★ 미래용 = 서명 검증 포함 완전 유효성 (= 결제 활성화 시점에 = is_valid 대체)
pub fn is_valid_signed(storage: &LicenseStorage, pubkey_pem: &str) -> bool {
    if storage.status != "active" { return false; }
    if storage.plan == "banned" { return false; }
    match decode_with_pubkey(&storage.token, pubkey_pem) {
        Ok(claims) => !is_expired(&claims),
        Err(_) => false,
    }
}
