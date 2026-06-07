const { createClient } = require('@supabase/supabase-js');
const WebSocket = require('ws');
const { AsyncLocalStorage } = require('async_hooks');

const requestStorage = new AsyncLocalStorage();

const clientOptions = {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
  realtime: {
    transport: WebSocket,
  },
};

const authClient = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY,
  clientOptions
);

function createUserClient(accessToken) {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    {
      ...clientOptions,
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
    }
  );
}

function runWithUserClient(accessToken, user, callback) {
  return requestStorage.run(
    { client: createUserClient(accessToken), user },
    callback
  );
}

const supabase = new Proxy({}, {
  get(_target, property) {
    const store = requestStorage.getStore();
    if (!store) {
      throw new Error('Supabase was used outside an authenticated request');
    }

    const value = store.client[property];
    return typeof value === 'function' ? value.bind(store.client) : value;
  },
});

module.exports = { supabase, authClient, runWithUserClient };
