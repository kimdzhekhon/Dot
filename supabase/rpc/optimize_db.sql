-- 0. 메모리 설정 증가 (에러 해결 핵심)
-- 인덱스 생성 시 "memory required is 35 MB" 에러를 해결하기 위해
-- 작업 메모리를 일시적으로 64MB로 늘립니다.
SET maintenance_work_mem = '64MB';

-- 1. Embed 컬럼 타입 영구 변경 (Text -> Vector)
alter table "Message_Spam"
alter column "Embed" type vector(768)
using (
  case 
    when "Embed" like '[%]' then "Embed"::vector
    else ('[' || "Embed" || ']')::vector
  end
);

-- 2. 인덱스 생성
-- 데이터가 약 2만 건이므로 lists=100 정도가 적당합니다.
-- 이제 메모리가 충분하므로 에러가 나지 않을 것입니다.
create index on "Message_Spam" using ivfflat ("Embed" vector_cosine_ops)
with (lists = 100);

-- 3. 함수 단순화
create or replace function match_messages (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  content text,
  similarity float
)
language plpgsql
security definer
as $$
begin
  return query
  select
    "Message_Spam"."content",
    (1 - ("Message_Spam"."Embed" <=> query_embedding)) as similarity
  from "Message_Spam"
  where 1 - ("Message_Spam"."Embed" <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;
