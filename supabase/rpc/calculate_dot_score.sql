-- calculate_dot_score 함수 재정의
-- 기존 함수가 'spam_keywords' 테이블을 참조하여 에러가 발생하므로, 
-- 해당 의존성을 제거하고 Google Safe Browsing 결과만 기반으로 점수를 계산하도록 수정합니다.

create or replace function calculate_dot_score(
  msg_body text,
  google_raw jsonb default '{}',
  vt_raw jsonb default '{}',
  target_url text default null
)
returns int
language plpgsql
as $$
declare
  v_score int := 0;
begin
  -- 1. Google Safe Browsing 결과 확인
  -- matches 항목이 있으면 위험한 URL로 간주하여 점수 100점 부여
  if (google_raw -> 'matches') is not null and jsonb_array_length(google_raw -> 'matches') > 0 then
    v_score := 100;
  end if;

  -- 2. (선택사항) 여기에 추가적인 키워드 검사 로직을 넣을 수 있습니다.
  -- 예: msg_body가 특정 패턴이라면 점수 추가 등.
  -- 현재는 spam_keywords 테이블이 없으므로 생략합니다.

  return v_score;
end;
$$;
