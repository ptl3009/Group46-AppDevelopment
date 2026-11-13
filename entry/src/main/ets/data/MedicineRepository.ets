import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export interface Medicine {
  id: number;
  name: string;
  category: string;
  expiryMonth: string;
  quantity: number;
  notes: string;
  imageUri: string;
}

const TABLE = 'medicine';
const CREATE_SQL = `CREATE TABLE IF NOT EXISTS ${TABLE} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT '',
  expiry_month TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  notes TEXT NOT NULL DEFAULT '',
  image_uri TEXT NOT NULL DEFAULT ''
)`;

export class MedicineRepository {
  private static store: relationalStore.RdbStore | null = null;
  private static opening: Promise<relationalStore.RdbStore> | null = null;

  static async initialize(context: common.UIAbilityContext): Promise<void> {
    await MedicineRepository.getStore(context);
  }

  private static async getStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
    if (MedicineRepository.store) return MedicineRepository.store;
    if (!MedicineRepository.opening) {
      MedicineRepository.opening = relationalStore.getRdbStore(context, {
        name: 'family_medicine.db', securityLevel: relationalStore.SecurityLevel.S1
      }).then(async (store: relationalStore.RdbStore) => {
        await store.executeSql(CREATE_SQL);
        try {
          await store.executeSql(`ALTER TABLE ${TABLE} ADD COLUMN image_uri TEXT NOT NULL DEFAULT ''`);
        } catch {
          // The column already exists in databases created with the current schema.
        }
        MedicineRepository.store = store;
        return store;
      });
    }
    return MedicineRepository.opening;
  }

  static async list(context: common.UIAbilityContext, keyword: string = ''): Promise<Medicine[]> {
    const store = await MedicineRepository.getStore(context);
    const predicates = new relationalStore.RdbPredicates(TABLE);
    if (keyword.trim().length > 0) predicates.contains('name', keyword.trim());
    predicates.orderByAsc('expiry_month');
    const result = await store.query(predicates, ['id', 'name', 'category', 'expiry_month', 'quantity', 'notes', 'image_uri']);
    const items: Medicine[] = [];
    try {
      while (result.goToNextRow()) {
        items.push({
          id: result.getLong(result.getColumnIndex('id')),
          name: result.getString(result.getColumnIndex('name')),
          category: result.getString(result.getColumnIndex('category')),
          expiryMonth: result.getString(result.getColumnIndex('expiry_month')),
          quantity: result.getLong(result.getColumnIndex('quantity')),
          notes: result.getString(result.getColumnIndex('notes')),
          imageUri: result.getString(result.getColumnIndex('image_uri'))
        });
      }
    } finally {
      result.close();
    }
    return items;
  }

  static async save(context: common.UIAbilityContext, item: Medicine): Promise<void> {
    const store = await MedicineRepository.getStore(context);
    const values: relationalStore.ValuesBucket = {
      name: item.name.trim(), category: item.category.trim(), expiry_month: item.expiryMonth,
      quantity: item.quantity, notes: item.notes.trim(), image_uri: item.imageUri
    };
    if (item.id > 0) {
      const predicates = new relationalStore.RdbPredicates(TABLE).equalTo('id', item.id);
      await store.update(values, predicates);
    } else {
      await store.insert(TABLE, values);
    }
  }

  static async remove(context: common.UIAbilityContext, id: number): Promise<void> {
    const store = await MedicineRepository.getStore(context);
    await store.delete(new relationalStore.RdbPredicates(TABLE).equalTo('id', id));
  }
}
