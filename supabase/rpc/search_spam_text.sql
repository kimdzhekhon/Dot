-- 1. 필수 확장 설치 (텍스트 유사도 검색용)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. 기존 함수 싹 정리
DROP FUNCTION IF EXISTS search_spam_text(text);
DROP FUNCTION IF EXISTS search_spam_text(text, float);
DROP FUNCTION IF EXISTS search_spam_text(text, double precision);
DROP FUNCTION IF EXISTS match_messages(vector(384), float, int);

-- 3. 텍스트 검색 함수 (오차 없는 정확한 매칭용)
CREATE OR REPLACE FUNCTION search_spam_text(p_query_text TEXT)
RETURNS TABLE(content TEXT, similarity FLOAT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.content,
        similarity(m.content, p_query_text)::FLOAT as sim
    FROM "Message_Spam_E5" m
    WHERE similarity(m.content, p_query_text) > 0.5  -- 텍스트 기준 50% 이상 일치
    ORDER BY sim DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 4. 벡터 검색 함수 (의미 기반 검색용)
CREATE OR REPLACE FUNCTION match_messages (
  query_embedding vector(384),
  match_threshold float,
  match_count int
)
RETURNS TABLE (content text, similarity float) AS $$
BEGIN
  RETURN QUERY
  SELECT m."content", (1 - (m."Embed" <=> query_embedding)) as similarity
  FROM "Message_Spam_E5" m
  WHERE m."Embed" IS NOT NULL AND (1 - (m."Embed" <=> query_embedding)) >= match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- 5. 스키마 캐시 갱신
NOTIFY pgrst, 'reload schema';
