const { createClient } = require('@supabase/supabase-js');
global.WebSocket = require('ws');

const SUPABASE_URL = 'https://mskizgdxpcuuqzjlblou.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testSignupAndFetch() {
  const email = `test_user_${Date.now()}@example.com`;
  const password = 'password123';
  
  console.log('Signing up user:', email);
  
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: 'Debug User',
        first_name: 'Debug',
        last_name: 'User',
        role: 'manager',
        phone: '+919876543210',
        gender: 'Male',
        zone: 'Western Railway',
        division: 'Mumbai',
        regions: ['Mumbai Central'],
        employee_id: 'EMP123',
        approval_status: 'approved'
      }
    }
  });

  if (authError) {
    console.error('Signup error:', authError.message);
    return;
  }
  
  console.log('Signup successful! UID:', authData.user.id);
  
  await new Promise(res => setTimeout(res, 2000));
  
  const { data: userData, error: userError } = await supabase
    .from('app_users')
    .select('*')
    .eq('id', authData.user.id)
    .single();
    
  if (userError) {
    console.error('Fetch error:', userError.message);
  } else {
    console.log('--- APP_USERS ROW ---');
    console.log(userData);
  }
}

testSignupAndFetch();
