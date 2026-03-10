import Sinon from 'sinon';
import { supabase } from '../../src/services/supabase';

/**
 * Replaces the live Supabase Client methods with Sinon Stubs
 */
export const mockSupabase = {
    auth: {
        signInWithPassword: Sinon.stub(supabase.auth, 'signInWithPassword'),
        signUp: Sinon.stub(supabase.auth, 'signUp'),
        getSession: Sinon.stub(supabase.auth, 'getSession'),
        onAuthStateChange: Sinon.stub(supabase.auth, 'onAuthStateChange'),
        admin: {
            createUser: Sinon.stub(supabase.auth.admin, 'createUser'),
            deleteUser: Sinon.stub(supabase.auth.admin, 'deleteUser')
        }
    },
    from: Sinon.stub(supabase, 'from'),
    channel: Sinon.stub(supabase, 'channel')
};

// Default behaviors for table queries
const defaultChain = {
    select: Sinon.stub().returnsThis(),
    insert: Sinon.stub().returnsThis(),
    update: Sinon.stub().returnsThis(),
    delete: Sinon.stub().returnsThis(),
    eq: Sinon.stub().returnsThis(),
    order: Sinon.stub().returnsThis(),
    single: Sinon.stub().resolves({ data: null, error: null }),
    then: (cb: any) => cb({ data: null, error: null })
};

mockSupabase.from.returns(defaultChain as any);

// Default behavior for realtime channels
mockSupabase.channel.returns({
    on: Sinon.stub().returnsThis(),
    subscribe: Sinon.stub().returnsThis(),
    send: Sinon.stub().resolves()
} as any);

// Initialize some defaults for auth to avoid network leaks and satisfy TS
mockSupabase.auth.signUp.resolves({ data: { user: null, session: null }, error: null } as any);
mockSupabase.auth.signInWithPassword.resolves({ data: { user: null, session: null }, error: null } as any);
