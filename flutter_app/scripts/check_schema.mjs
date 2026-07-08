const url = 'https://mskizgdxpcuuqzjlblou.supabase.co/rest/v1';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4';

async function checkTable(table) {
  const res = await fetch(`${url}/${table}?limit=1`, {
    headers: { 'apikey': key, 'Authorization': `Bearer ${key}` }
  });
  if (res.ok) {
    const data = await res.json();
    console.log(`--- ${table} ---`);
    if (data.length > 0) {
      console.log(Object.keys(data[0]).join(', '));
    } else {
      console.log('No rows, cannot infer schema');
    }
  } else {
    console.log(`Failed to fetch ${table}:`, await res.text());
  }
}

async function run() {
  await checkTable('app_vehicles');
  await checkTable('trackman_tasks');
  await checkTable('trackman_issues');
}
run();
