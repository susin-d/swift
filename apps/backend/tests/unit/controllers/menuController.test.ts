import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import {
    createMenu,
    createMenuItem,
    updateMenuItem,
    getMyVendorMenu,
} from '../../../src/controllers/menuController';

describe('Menu Controller - Authorization and ownership', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('createMenu uses authenticated vendor scope instead of body vendor_id', async () => {
        const ownerVendorMaybeSingle = Sinon.stub().resolves({ data: { id: 'vendor-owner' }, error: null });
        const ownerVendorEq = Sinon.stub().returns({ maybeSingle: ownerVendorMaybeSingle });
        const ownerVendorSelect = Sinon.stub().returns({ eq: ownerVendorEq });

        const insertedMenu = { id: 'menu-1', vendor_id: 'vendor-owner', category_name: 'Starters', sort_order: 1 };
        const menuSingle = Sinon.stub().resolves({ data: insertedMenu, error: null });
        const menuSelect = Sinon.stub().returns({ single: menuSingle });
        const menuInsert = Sinon.stub().returns({ select: menuSelect });

        fromStub.onCall(0).returns({ select: ownerVendorSelect } as any);
        fromStub.onCall(1).returns({ insert: menuInsert } as any);

        const request: any = {
            user: { sub: 'owner-user', role: 'vendor' },
            body: { vendor_id: 'malicious-vendor', category_name: 'Starters', sort_order: 1 },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createMenu(request, reply);

        Sinon.assert.calledWithExactly(menuInsert, {
            vendor_id: 'vendor-owner',
            category_name: 'Starters',
            sort_order: 1,
        });
        Sinon.assert.calledWithExactly(reply.code, 201);
    });

    it('createMenuItem blocks cross-vendor writes', async () => {
        const ownerVendorMaybeSingle = Sinon.stub().resolves({ data: { id: 'vendor-a' }, error: null });
        const ownerVendorEq = Sinon.stub().returns({ maybeSingle: ownerVendorMaybeSingle });
        const ownerVendorSelect = Sinon.stub().returns({ eq: ownerVendorEq });

        const menuMaybeSingle = Sinon.stub().resolves({ data: { id: 'menu-1', vendor_id: 'vendor-b' }, error: null });
        const menuEq = Sinon.stub().returns({ maybeSingle: menuMaybeSingle });
        const menuSelect = Sinon.stub().returns({ eq: menuEq });

        fromStub.onCall(0).returns({ select: ownerVendorSelect } as any);
        fromStub.onCall(1).returns({ select: menuSelect } as any);

        const request: any = {
            user: { sub: 'owner-user', role: 'vendor' },
            body: { menu_id: 'menu-1', name: 'Samosa', price: 30 },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        const err = await createMenuItem(request, reply).catch((e) => e);
        expect(err.statusCode).toBe(403);
    });

    it('updateMenuItem validates ownership via menu relation before update', async () => {
        const ownerVendorMaybeSingle = Sinon.stub().resolves({ data: { id: 'vendor-a' }, error: null });
        const ownerVendorEq = Sinon.stub().returns({ maybeSingle: ownerVendorMaybeSingle });
        const ownerVendorSelect = Sinon.stub().returns({ eq: ownerVendorEq });

        const itemMaybeSingle = Sinon.stub().resolves({ data: { id: 'item-1', menu_id: 'menu-1' }, error: null });
        const itemEq = Sinon.stub().returns({ maybeSingle: itemMaybeSingle });
        const itemSelect = Sinon.stub().returns({ eq: itemEq });

        const menuMaybeSingle = Sinon.stub().resolves({ data: { vendor_id: 'vendor-a' }, error: null });
        const menuEq = Sinon.stub().returns({ maybeSingle: menuMaybeSingle });
        const menuSelect = Sinon.stub().returns({ eq: menuEq });

        const updatedItem = { id: 'item-1', name: 'Paneer Roll' };
        const updateSingle = Sinon.stub().resolves({ data: updatedItem, error: null });
        const updateSelect = Sinon.stub().returns({ single: updateSingle });
        const updateEq = Sinon.stub().returns({ select: updateSelect });
        const updateStub = Sinon.stub().returns({ eq: updateEq });

        fromStub.onCall(0).returns({ select: ownerVendorSelect } as any);
        fromStub.onCall(1).returns({ select: itemSelect } as any);
        fromStub.onCall(2).returns({ select: menuSelect } as any);
        fromStub.onCall(3).returns({ update: updateStub } as any);

        const request: any = {
            user: { sub: 'owner-user', role: 'vendor' },
            params: { id: 'item-1' },
            body: { name: 'Paneer Roll' },
        };
        const reply: any = { send: Sinon.stub() };

        await updateMenuItem(request, reply);

        Sinon.assert.calledOnce(updateStub);
        expect(reply.send.firstCall.args[0]).toEqual(updatedItem);
    });

    it('getMyVendorMenu resolves active staff membership when owner mapping does not exist', async () => {
        const ownerVendorMaybeSingle = Sinon.stub().resolves({ data: null, error: null });
        const ownerVendorEq = Sinon.stub().returns({ maybeSingle: ownerVendorMaybeSingle });
        const ownerVendorSelect = Sinon.stub().returns({ eq: ownerVendorEq });

        const staffMaybeSingle = Sinon.stub().resolves({ data: { vendor_id: 'vendor-staff' }, error: null });
        const staffLimit = Sinon.stub().returns({ maybeSingle: staffMaybeSingle });
        const staffOrder = Sinon.stub().returns({ limit: staffLimit });
        const staffEqStatus = Sinon.stub().returns({ order: staffOrder });
        const staffEqUser = Sinon.stub().returns({ eq: staffEqStatus });
        const staffSelect = Sinon.stub().returns({ eq: staffEqUser });

        const menus = [{ id: 'menu-1', vendor_id: 'vendor-staff', category_name: 'Meals', menu_items: [] }];
        const menuEq = Sinon.stub().resolves({ data: menus, error: null });
        const menuSelect = Sinon.stub().returns({ eq: menuEq });

        fromStub.onCall(0).returns({ select: ownerVendorSelect } as any);
        fromStub.onCall(1).returns({ select: staffSelect } as any);
        fromStub.onCall(2).returns({ select: menuSelect } as any);

        const request: any = { user: { sub: 'staff-user', role: 'vendor' } };
        const reply: any = { send: Sinon.stub() };

        await getMyVendorMenu(request, reply);

        const payload = reply.send.firstCall.args[0];
        expect(payload.categories).toHaveLength(1);
        expect(payload.categories[0].vendor_id).toBe('vendor-staff');
    });
});
