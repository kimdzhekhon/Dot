-- check_web_list RPC
-- 사이트 주소를 입력받아 화이트리스트와 블랙리스트를 순차적으로 조회합니다.
-- 1. 화이트리스트에 있으면 사이트명을 반환하고 종료합니다.
-- 2. 화이트리스트에 없으면 블랙리스트를 확인합니다.
-- 3. 블랙리스트에 있으면 blacklisted 상태를 반환합니다.

CREATE OR REPLACE FUNCTION check_web_list(p_url text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_site_name text;
  v_reg_subject text;
  v_reg_date text;
  v_found_blacklist boolean;
BEGIN
  -- 1. Check Whitelist (Web_Whitelist)
  SELECT "사이트명", "등록 주체", "등록 날짜" 
  INTO v_site_name, v_reg_subject, v_reg_date
  FROM "Web_Whitelist" 
  WHERE "주소" IN (
    p_url, 
    'http://'||p_url, 'https://'||p_url, 'hxxp://'||p_url, 'hxxps://'||p_url,
    p_url||'/', 
    'http://'||p_url||'/', 'https://'||p_url||'/', 'hxxp://'||p_url||'/', 'hxxps://'||p_url||'/'
  )
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'found', true, 
      'status', 'whitelisted', 
      'site_name', v_site_name,
      'reg_subject', v_reg_subject,
      'reg_date', v_reg_date
    );
  END IF;

  -- 2. Check Blacklist (Web_Blacklist)
  SELECT "등록 주체", "등록 날짜"
  INTO v_reg_subject, v_reg_date
  FROM "Web_Blacklist" 
  WHERE "홈페이지주소" IN (
    p_url, 
    'http://'||p_url, 'https://'||p_url, 'hxxp://'||p_url, 'hxxps://'||p_url,
    p_url||'/', 
    'http://'||p_url||'/', 'https://'||p_url||'/', 'hxxp://'||p_url||'/', 'hxxps://'||p_url||'/'
  )
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'found', true, 
      'status', 'blacklisted',
      'reg_subject', v_reg_subject,
      'reg_date', v_reg_date
    );
  END IF;

  -- 3. Not Found
  RETURN jsonb_build_object(
    'found', false, 
    'status', 'none'
  );
END;
$$;

-- RLS (Row Level Security) 설정
-- Web_Whitelist 및 Web_Blacklist 테이블에 대해 읽기 권한을 허용합니다.

-- 1. RLS 활성화
ALTER TABLE "Web_Whitelist" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Web_Blacklist" ENABLE ROW LEVEL SECURITY;

-- 2. 정책 추가 (모든 사용자에게 SELECT 허용)
-- 인증된 사용자(authenticated) 또는 익명 사용자(anon)가 조회할 수 있도록 설정합니다.

DROP POLICY IF EXISTS "Allow public read for Web_Whitelist" ON "Web_Whitelist";
CREATE POLICY "Allow public read for Web_Whitelist" 
ON "Web_Whitelist" 
FOR SELECT 
TO public 
USING (true);

DROP POLICY IF EXISTS "Allow public read for Web_Blacklist" ON "Web_Blacklist";
CREATE POLICY "Allow public read for Web_Blacklist" 
ON "Web_Blacklist" 
FOR SELECT 
TO public 
USING (true);

-- 권한 부여 (public 스키마의 해당 테이블에 대한 SELECT 권한을 anon, authenticated 역할에 부여)
GRANT SELECT ON "Web_Whitelist" TO anon, authenticated;
GRANT SELECT ON "Web_Blacklist" TO anon, authenticated;
