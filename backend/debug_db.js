global.WebSocket = require('ws');
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://mskizgdxpcuuqzjlblou.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkDatabase() {
  try {
    const { data: usersData, error: usersError } = await supabase
      .from('app_users')
      .select('*')
      .limit(5);

    if (usersError) {
      console.error('Error fetching app_users:', usersError.message);
    } else {
      console.log('--- APP_USERS DATA ---');
      console.log(JSON.stringify(usersData, null, 2));
    }
  } catch (err) {
    console.error('Unexpected error:', err);
  }
}

checkDatabase();
