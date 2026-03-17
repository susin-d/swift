import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import {
    createMenu,
    getVendorMenus,
    updateMenu,
    deleteMenu,
    createMenuItem,
    updateMenuItem,
    deleteMenuItem,
    getMyVendorMenu,
} from '../../../src/controllers/menuController';

describe('Menu Controller - Menu CRUD', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    describe('createMenu', () => {
        it('inserts a new menu category and returns 201', async () => {
            const menuData = { id: 'menu-1', vendor_id: 'v-1', category_name: 'Starters', sort_order: 1 };

            const singleStub = Sinon.stub().resolves({ data: menuData, error: null });
            const selectStub = Sinon.stub().returns({ single: singleStub });
            const insertStub = Sinon.stub().returns({ select: selectStub });

            fromStub.withArgs('menus').returns({ insert: insertStub } as any);

            const request: any = { body: { vendor_id: 'v-1', category_name: 'Starters', sort_order: 1 } };
            const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

            await createMenu(request, reply);

            Sinon.assert.calledWithExactly(insertStub, { vendor_id: 'v-1', category_name: 'Starters', sort_order: 1 });
            Sinon.assert.calledWithExactly(reply.code, 201);
            expect(reply.send.firstCall.args[0]).toEqual(menuData);
        });

        it('throws on Supabase insert error', async () => {
            const dbError = new Error('insert failed');
            const singleStub = Sinon.stub().resolves({ data: null, error: dbError });
            const selectStub = Sinon.stub().returns({ single: singleStub });
            const insertStub = Sinon.stub().returns({ select: selectStub });

            fromStub.withArgs('menus').returns({ insert: insertStub } as any);

            const request: any = { body: { vendor_id: 'v-1', category_name: 'Starters', sort_order: 1 } };
            const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

            await expect(createMenu(request, reply)).rejects.toThrow('insert failed');
        });
    });

    describe('getVendorMenus', () => {
        it('returns menus with nested menu_items for a given vendor', async () => {
            const menus = [{ id: 'menu-1', vendor_id: 'v-1', category_name: 'Starters', menu_items: [] }];

            const eqStub = Sinon.stub().resolves({ data: menus, error: null });
            const selectStub = Sinon.stub().returns({ eq: eqStub });

            fromStub.withArgs('menus').returns({ select: selectStub } as any);

            const request: any = { params: { vendorId: 'v-1' } };
            const reply: any = { send: Sinon.stub() };

            await getVendorMenus(request, reply);

            Sinon.assert.calledWithExactly(selectStub, '*, menu_items(*)');
            Sinon.assert.calledWithExactly(eqStub, 'vendor_id', 'v-1');
            expect(reply.send.firstCall.args[0]).toEqual(menus);
        });
    });

    describe('updateMenu', () => {
        it('updates category_name and sort_order and returns updated record', async () => {
            const updated = { id: 'menu-1', category_name: 'Mains', sort_order: 2 };

            const singleStub = Sinon.stub().resolves({ data: updated, error: null });
            const selectStub = Sinon.stub().returns({ single: singleStub });
            const eqStub = Sinon.stub().returns({ select: selectStub });
            const updateStub = Sinon.stub().returns({ eq: eqStub });

            fromStub.withArgs('menus').returns({ update: updateStub } as any);

            const request: any = { params: { id: 'menu-1' }, body: { category_name: 'Mains', sort_order: 2 } };
            const reply: any = { send: Sinon.stub() };

            await updateMenu(request, reply);

            Sinon.assert.calledWithExactly(updateStub, { category_name: 'Mains', sort_order: 2 });
            Sinon.assert.calledWithExactly(eqStub, 'id', 'menu-1');
            expect(reply.send.firstCall.args[0]).toEqual(updated);
        });
    });

    describe('deleteMenu', () => {
        it('deletes a menu by id and responds 204', async () => {
            const eqStub = Sinon.stub().resolves({ error: null });
            const deleteStub = Sinon.stub().returns({ eq: eqStub });

            fromStub.withArgs('menus').returns({ delete: deleteStub } as any);

            const request: any = { params: { id: 'menu-1' } };
            const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

            await deleteMenu(request, reply);

            Sinon.assert.calledWithExactly(eqStub, 'id', 'menu-1');
            Sinon.assert.calledWithExactly(reply.code, 204);
        });
    });
});

describe('Menu Controller - Menu Item CRUD', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    describe('createMenuItem', () => {
        it('inserts a new menu item and returns 201', async () => {
            const item = { id: 'item-1', menu_id: 'menu-1', name: 'Samosa', price: 30 };

            const singleStub = Sinon.stub().resolves({ data: item, error: null });
            const selectStub = Sinon.stub().returns({ single: singleStub });
            const insertStub = Sinon.stub().returns({ select: selectStub });

            fromStub.withArgs('menu_items').returns({ insert: insertStub } as any);

            const request: any = {
                body: { menu_id: 'menu-1', name: 'Samosa', description: '', price: 30, is_available: true, image_url: null },
            };
            const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

            await createMenuItem(request, reply);

            Sinon.assert.calledWithExactly(reply.code, 201);
            expect(reply.send.firstCall.args[0]).toEqual(item);
        });

        it('throws on Supabase error', async () => {
            const dbError = new Error('constraint violation');
            const singleStub = Sinon.stub().resolves({ data: null, error: dbError });
            const selectStub = Sinon.stub().returns({ single: singleStub });
            const insertStub = Sinon.stub().returns({ select: selectStub });

            fromStub.withArgs('menu_items').returns({ insert: insertStub } as any);

            const request: any = {
                body: { menu_id: 'menu-1', name: 'Samosa', description: '', price: 30, is_available: true, image_url: null },
            };
            const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

            await expect(createMenuItem(request, reply)).rejects.toThrow('constraint violation');
        });
    });

    describe('updateMenuItem', () => {
        it('updates item fields and returns updated record', async () => {
            const updated = { id: 'item-1', name: 'Paneer Tikka', price: 120 };

            const singleStub = Sinon.stub().resolves({ data: updated, error: null });
            const selectStub = Sinon.stub().returns({ single: singleStub });
            const eqStub = Sinon.stub().returns({ select: selectStub });
            const updateStub = Sinon.stub().returns({ eq: eqStub });

            fromStub.withArgs('menu_items').returns({ update: updateStub } as any);

            const request: any = { params: { id: 'item-1' }, body: { name: 'Paneer Tikka', price: 120 } };
            const reply: any = { send: Sinon.stub() };

            await updateMenuItem(request, reply);

            Sinon.assert.calledWithExactly(updateStub, { name: 'Paneer Tikka', price: 120 });
            Sinon.assert.calledWithExactly(eqStub, 'id', 'item-1');
            expect(reply.send.firstCall.args[0]).toEqual(updated);
        });
    });

    describe('deleteMenuItem', () => {
        it('deletes an item by id and responds 204', async () => {
            const eqStub = Sinon.stub().resolves({ error: null });
            const deleteStub = Sinon.stub().returns({ eq: eqStub });

            fromStub.withArgs('menu_items').returns({ delete: deleteStub } as any);

            const request: any = { params: { id: 'item-1' } };
            const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

            await deleteMenuItem(request, reply);

            Sinon.assert.calledWithExactly(eqStub, 'id', 'item-1');
            Sinon.assert.calledWithExactly(reply.code, 204);
        });
    });

    describe('getMyVendorMenu', () => {
        it('returns flattened items and categories for the authenticated vendor', async () => {
            const vendor = { id: 'v-1' };
            const menus = [
                { id: 'menu-1', category_name: 'Starters', vendor_id: 'v-1', menu_items: [{ id: 'item-1', name: 'Samosa', price: 30 }] },
            ];

            const vendorSingleStub = Sinon.stub().resolves({ data: vendor, error: null });
            const vendorEqStub = Sinon.stub().returns({ single: vendorSingleStub });
            const vendorSelectStub = Sinon.stub().returns({ eq: vendorEqStub });

            const menuEqStub = Sinon.stub().resolves({ data: menus, error: null });
            const menuSelectStub = Sinon.stub().returns({ eq: menuEqStub });

            fromStub.onFirstCall().returns({ select: vendorSelectStub } as any);
            fromStub.onSecondCall().returns({ select: menuSelectStub } as any);

            const request: any = { user: { sub: 'user-1' } };
            const reply: any = { send: Sinon.stub() };

            await getMyVendorMenu(request, reply);

            Sinon.assert.calledWithExactly(vendorSelectStub, 'id');
            Sinon.assert.calledWithExactly(vendorEqStub, 'owner_id', 'user-1');
            Sinon.assert.calledWithExactly(menuSelectStub, '*, menu_items(*)');
            Sinon.assert.calledWithExactly(menuEqStub, 'vendor_id', 'v-1');

            const sentData = reply.send.firstCall.args[0];
            expect(sentData).toHaveProperty('items');
            expect(sentData).toHaveProperty('categories');
            expect(sentData.items).toHaveLength(1);
            expect(sentData.items[0]).toMatchObject({ id: 'item-1', category: 'Starters' });
        });

        it('throws 404 when vendor profile is not found', async () => {
            const vendorSingleStub = Sinon.stub().resolves({ data: null, error: new Error('not found') });
            const vendorEqStub = Sinon.stub().returns({ single: vendorSingleStub });
            const vendorSelectStub = Sinon.stub().returns({ eq: vendorEqStub });

            fromStub.onFirstCall().returns({ select: vendorSelectStub } as any);

            const request: any = { user: { sub: 'user-xyz' } };
            const reply: any = { send: Sinon.stub() };

            const err = await getMyVendorMenu(request, reply).catch(e => e);
            expect(err.message).toBe('Vendor profile not found');
            expect(err.statusCode).toBe(404);
        });
    });
});
