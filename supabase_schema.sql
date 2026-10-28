-- 自習教室配置アプリ：共有状態テーブル
-- 注意：このSQLは「ログインなしで全員が編集する」テスト運用向けです。
-- 公開するとURLを知る第三者もデータ閲覧・変更ができる可能性があります。
-- 実データや個人情報を入れず、まずテスト用データで動作確認してください。

create table if not exists public.app_state (
  id integer primary key default 1 check (id = 1),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.app_state enable row level security;

-- 既存の試行用ポリシーがある場合に重複しないよう削除してから作成
 drop policy if exists "public can read app state" on public.app_state;
 drop policy if exists "public can insert app state" on public.app_state;
 drop policy if exists "public can update app state" on public.app_state;

-- 無ログインでの共有を実現するための公開ポリシー（テスト用途のみ）
create policy "public can read app state"
  on public.app_state for select to anon, authenticated using (id = 1);
create policy "public can insert app state"
  on public.app_state for insert to anon, authenticated with check (id = 1);
create policy "public can update app state"
  on public.app_state for update to anon, authenticated using (id = 1) with check (id = 1);

-- Realtime publicationへ追加（すでに追加済みの場合は何もしない）
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'app_state'
  ) then
    alter publication supabase_realtime add table public.app_state;
  end if;
end $$;
