const url = 'https://mskizgdxpcuuqzjlblou.supabase.co/rest/v1';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4';

async function deleteBroadcasts() {
  const res = await fetch(`${url}/broadcast_messages?target_role=neq.nobody`, {
    method: 'DELETE',
    headers: { 'apikey': key, 'Authorization': `Bearer ${key}` }
  });
  if (res.ok) {
    console.log('Successfully deleted broadcasts');
  } else {
    console.log('Failed to delete broadcasts:', await res.text());
  }
}

deleteBroadcasts();
