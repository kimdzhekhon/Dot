-- 1. 기존 함수 삭제
drop function if exists match_messages(vector, float, int);

-- 2. match_messages 함수 재생성
-- 에러 해결: column reference "content" is ambiguous
-- 원인: 반환할 컬럼명 'content'가 함수의 리턴 타입 정의(content text)와 이름이 겹쳐서 모호함 발생
-- 해결: "Message_Spam"."content" 라고 명확히 테이블명을 붙여주고, 반환 컬럼명에는 별칭(AS)을 주어 구분 (사실 테이블명만 붙여도 해결됨)

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
    "Message_Spam"."content",  -- 테이블명 명시 필수
    (1 - (
      case 
        when "Message_Spam"."Embed" like '[%]' then "Message_Spam"."Embed"::vector
        else ('[' || "Message_Spam"."Embed" || ']')::vector
      end 
      <=> query_embedding
    )) as similarity
  from "Message_Spam"
  where (1 - (
      case 
        when "Message_Spam"."Embed" like '[%]' then "Message_Spam"."Embed"::vector
        else ('[' || "Message_Spam"."Embed" || ']')::vector
      end 
      <=> query_embedding
    )) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;
