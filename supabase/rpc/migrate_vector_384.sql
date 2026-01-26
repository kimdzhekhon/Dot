-- 1. 새 테이블 생성 (384차원 전용)
CREATE TABLE IF NOT EXISTS "Message_Spam_E5" (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  content text NOT NULL,
  "Embed" vector(384),
  "Date" text,
  created_at timestamptz DEFAULT now()
);

-- 2. 벡터 인덱스 생성
CREATE INDEX IF NOT EXISTS "Message_Spam_E5_Embed_idx" 
ON "Message_Spam_E5" USING ivfflat ("Embed" vector_cosine_ops)
WITH (lists = 100);

-- 3. 검색 함수(match_messages)를 새 테이블을 바라보도록 수정
CREATE OR REPLACE FUNCTION match_messages (
  query_embedding vector(384),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  content text,
  similarity float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    m."content",
    (1 - (m."Embed" <=> query_embedding)) as similarity
  FROM "Message_Spam_E5" m
  WHERE m."Embed" IS NOT NULL 
    AND 1 - (m."Embed" <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$;
