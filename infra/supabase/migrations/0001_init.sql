-- Ember data model (§5C). RLS enabled everywhere; the Runner uses the
-- service role, clients may read their own rows directly.
create extension if not exists vector;

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  plan text not null default 'free' check (plan in ('free', 'pro')),
  created_at timestamptz not null default now()
);

create table public.workspaces (
  id text primary key,
  owner_id text not null,
  name text not null,
  status text not null check (status in ('stopped', 'starting', 'running', 'error')),
  container_id text,
  cpu numeric not null default 2,
  ram_mb int not null default 4096,
  disk_gb int not null default 10,
  created_at timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);
create index on public.workspaces (owner_id);

create table public.projects (
  id text primary key,
  workspace_id text not null references public.workspaces on delete cascade,
  name text not null,
  path text generated always as ('projects/' || name) stored,
  template text not null default 'empty',
  status text not null check (status in ('creating', 'ready', 'error')),
  last_model text,
  created_at timestamptz not null default now(),
  unique (workspace_id, name)
);

create table public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.projects on delete cascade,
  title text not null default '',
  created_at timestamptz not null default now()
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant', 'tool')),
  content text not null,
  tool_calls jsonb,
  tokens int,
  created_at timestamptz not null default now()
);

create table public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.projects on delete cascade,
  mode text not null,
  status text not null,
  phase text,
  state_json jsonb not null default '{}',
  iterations int not null default 0,
  created_at timestamptz not null default now()
);

create table public.mockup_sets (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.projects on delete cascade,
  generation int not null,
  styles_json jsonb not null,
  chosen_index int,
  created_at timestamptz not null default now()
);

create table public.build_jobs (
  id text primary key,
  project_id text not null references public.projects on delete cascade,
  kind text not null check (kind in ('web', 'apk')),
  status text not null,
  log_url text,
  artifact_url text,
  started_at timestamptz,
  finished_at timestamptz
);

create table public.code_chunks (
  id bigserial primary key,
  project_id text not null references public.projects on delete cascade,
  file text not null,
  start_line int not null,
  end_line int not null,
  hash text not null,
  embedding vector(1536)
);
create index on public.code_chunks (project_id, file);

create table public.api_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  provider text not null,
  ciphertext bytea not null,
  iv bytea not null,
  created_at timestamptz not null default now(),
  unique (user_id, provider)
);

create table public.usage (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  provider text not null,
  model text not null,
  input_tokens int not null,
  output_tokens int not null,
  cost_usd numeric(12, 6) not null,
  at timestamptz not null default now()
);

-- RLS
alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.projects enable row level security;
alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;
alter table public.agent_runs enable row level security;
alter table public.mockup_sets enable row level security;
alter table public.build_jobs enable row level security;
alter table public.code_chunks enable row level security;
alter table public.api_keys enable row level security;
alter table public.usage enable row level security;

create policy own_profile on public.profiles for select using (id = auth.uid());
create policy own_workspaces on public.workspaces for select using (owner_id = auth.uid()::text);
create policy own_projects on public.projects for select
  using (exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = auth.uid()::text));
create policy own_threads on public.chat_threads for all
  using (exists (select 1 from public.projects p join public.workspaces w on w.id = p.workspace_id
                 where p.id = project_id and w.owner_id = auth.uid()::text));
create policy own_messages on public.chat_messages for all
  using (exists (select 1 from public.chat_threads t join public.projects p on p.id = t.project_id
                 join public.workspaces w on w.id = p.workspace_id
                 where t.id = thread_id and w.owner_id = auth.uid()::text));
create policy own_usage on public.usage for select using (user_id = auth.uid());
-- api_keys, code_chunks, agent_runs, mockup_sets, build_jobs: service role only (no client policies).
