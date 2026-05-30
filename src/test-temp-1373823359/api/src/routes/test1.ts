import { Router } from 'express';
const router = Router();

router.get('/items', async (req, res) => {
    const items = await db.collection('items').find().toArray();
    res.json(items);
});

export default router;
