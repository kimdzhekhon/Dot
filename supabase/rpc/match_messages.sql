-- 1. 기존 함수 삭제
drop function if exists match_messages(vector, float, int);

-- 2. match_messages 함수 재생성
-- SECURITY DEFINER 옵션 추가: 함수 실행 시 생성자(postgres) 권한으로 실행되어 RLS 정책을 우회하고 테이블을 조회할 수 있습니다.
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
security definer -- 권한 문제 해결
as $$
begin
  return query
  select
    "Message_Spam".content,
    (1 - ("Message_Spam"."Embed" <=> query_embedding)) as similarity
  from "Message_Spam"
  where 1 - ("Message_Spam"."Embed" <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;
