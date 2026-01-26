-- check_web_list RPC
-- 사이트 주소를 입력받아 화이트리스트와 블랙리스트를 순차적으로 조회합니다.
-- 1. 화이트리스트에 있으면 사이트명을 반환하고 종료합니다.
-- 2. 화이트리스트에 없으면 블랙리스트를 확인합니다.
-- 3. 블랙리스트에 있으면 blacklisted 상태를 반환합니다.

CREATE OR REPLACE FUNCTION check_web_list(p_url text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_site_name text;
  v_found_blacklist boolean;
BEGIN
  -- 1. Check Whitelist (Web_Whitelist)
  SELECT "사이트명" INTO v_site_name 
  FROM "Web_Whitelist" 
  WHERE "주소" = p_url 
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'found', true, 
      'status', 'whitelisted', 
      'site_name', v_site_name
    );
  END IF;

  -- 2. Check Blacklist (Web_Blacklist)
  SELECT EXISTS (
    SELECT 1 
    FROM "Web_Blacklist" 
    WHERE "홈페이지주소" = p_url
  ) INTO v_found_blacklist;

  IF v_found_blacklist THEN
    RETURN jsonb_build_object(
      'found', true, 
      'status', 'blacklisted'
    );
  END IF;

  -- 3. Not Found
  RETURN jsonb_build_object(
    'found', false, 
    'status', 'none'
  );
END;
$$;
