import { Medicine, MedicineRepository } from '../data/MedicineRepository';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

@Entry
@Component
struct Index {
  @State medicines: Medicine[] = [];
  @State visibleMedicines: Medicine[] = [];
  @State keyword: string = '';
  @State editingId: number = 0;
  @State name: string = '';
  @State category: string = '';
  @State expiryMonth: string = '';
  @State quantity: string = '1';
  @State notes: string = '';
  @State imageUri: string = '';
  @State selectedCategory: string = '全部';
  @State categories: string[] = ['全部'];
  @State status: string = '正在连接本地药品库…';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    try {
      this.medicines = await MedicineRepository.list(this.context, this.keyword);
      const uniqueCategories = Array.from(new Set(this.medicines.map((item: Medicine) => item.category || '未分类')));
      this.categories = ['全部', ...uniqueCategories];
      this.updateVisibleMedicines();
      this.status = `${this.medicines.length} 条药品记录 · 按效期升序`;
    } catch {
      this.status = '药品库暂不可用，请重新打开应用';
    }
  }

  private clearForm(): void {
    this.editingId = 0;
    this.name = '';
    this.category = '';
    this.expiryMonth = '';
    this.quantity = '1';
    this.notes = '';
    this.imageUri = '';
  }

  private updateVisibleMedicines(): void {
    if (this.selectedCategory === '全部') {
      this.visibleMedicines = this.medicines.slice();
    } else {
      this.visibleMedicines = this.medicines.filter((item: Medicine) =>
        (item.category || '未分类') === this.selectedCategory);
    }
  }

  private edit(item: Medicine): void {
    this.editingId = item.id;
    this.name = item.name;
    this.category = item.category;
    this.expiryMonth = item.expiryMonth;
    this.quantity = `${item.quantity}`;
    this.notes = item.notes;
    this.imageUri = item.imageUri;
  }

  private async save(): Promise<void> {
    if (!this.name.trim() || !/^\d{4}-(0[1-9]|1[0-2])$/.test(this.expiryMonth)) {
      this.status = '请填写药品名称，并按 YYYY-MM 填写有效期';
      return;
    }
    const amount = Number.parseInt(this.quantity, 10);
    if (!Number.isFinite(amount) || amount < 0) {
      this.status = '数量请填写大于或等于 0 的整数';
      return;
    }
    try {
      await MedicineRepository.save(this.context, {
        id: this.editingId, name: this.name, category: this.category,
        expiryMonth: this.expiryMonth, quantity: amount, notes: this.notes, imageUri: this.imageUri
      });
      this.clearForm();
      await this.refresh();
      this.status = '记录已保存';
    } catch {
      this.status = '保存失败，请检查输入后重试';
    }
  }

  private chooseImage(): void {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    picker.select(options).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (result.photoUris.length > 0) this.imageUri = result.photoUris[0];
    }).catch(() => this.status = '图片选择未完成');
  }

  private confirmRemove(item: Medicine): void {
    AlertDialog.show({
      title: '删除药品记录？',
      message: `「${item.name}」将从本地药箱中移除。`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', fontColor: '#B44A43', action: () => {
        MedicineRepository.remove(this.context, item.id).then(() => {
          this.refresh();
          this.status = `已删除「${item.name}」`;
        }).catch(() => this.status = '删除失败，请重试');
      } }
    });
  }

  @Builder
  private field(label: string, value: string, change: (text: string) => void, hint: string, type: InputType = InputType.Normal) {
    Column({ space: 6 }) {
      Text(label).fontSize(13).fontColor('#64748B').fontWeight(FontWeight.Medium).width('100%')
      TextInput({ text: value, placeholder: hint })
        .type(type).onChange(change)
        .height(44).backgroundColor('#F6F8FA').borderRadius(12).padding({ left: 12, right: 12 })
    }.width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Column({ space: 5 }) {
            Text('家庭药箱').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#16251F')
            Text('让每一盒药，都在清单里').fontSize(14).fontColor('#718078')
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Text('M1 · 本地台账').fontSize(12).fontColor('#236B50').backgroundColor('#E7F3EC')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 }).borderRadius(20)
        }.width('100%')

        Row({ space: 8 }) {
          Text('▦').fontSize(21).fontColor('#26714F')
          Column({ space: 2 }) {
            Text('药品清单').fontSize(15).fontWeight(500).fontColor('#1D2B24')
            Text(this.status).fontSize(12).fontColor('#718078')
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Text(`${this.medicines.length}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#26714F')
        }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(18)

        Column({ space: 10 }) {
          Text('按分类浏览').fontSize(15).fontWeight(500).fontColor('#1D2B24').width('100%')
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.categories, (category: string) => {
                Text(category).fontSize(13).fontColor(this.selectedCategory === category ? '#FFFFFF' : '#52635A')
                  .backgroundColor(this.selectedCategory === category ? '#287451' : '#F1F5F1')
                  .padding({ left: 14, right: 14, top: 9, bottom: 9 }).borderRadius(18)
                  .onClick(() => {
                    this.selectedCategory = category;
                    this.updateVisibleMedicines();
                  })
              }, (category: string) => category)
            }
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
        }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(18)

        Column({ space: 10 }) {
          Text('搜索药品').fontSize(16).fontWeight(500).fontColor('#1D2B24').width('100%')
          TextInput({ text: this.keyword, placeholder: '输入名称，快速查找' }).onChange((v: string) => {
            this.keyword = v;
            this.refresh();
          }).height(44).backgroundColor('#F6F8FA').borderRadius(12).padding({ left: 12, right: 12 })
        }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(18)

        Column({ space: 12 }) {
          Row() {
            Text(this.editingId > 0 ? '编辑药品' : '登记药品').fontSize(16).fontWeight(500).fontColor('#1D2B24')
            Blank()
            if (this.editingId > 0) {
              Text('取消编辑').fontSize(12).fontColor('#26714F').onClick(() => this.clearForm())
            }
          }.width('100%')
          this.field('药品名称', this.name, (v: string) => this.name = v, '例如：感冒灵')
          Row({ space: 10 }) {
            Column() { this.field('分类', this.category, (v: string) => this.category = v, '例如：常用药') }.layoutWeight(1)
            Column() { this.field('有效期月份', this.expiryMonth, (v: string) => this.expiryMonth = v, 'YYYY-MM', InputType.Normal) }.layoutWeight(1)
          }.width('100%')
          Row({ space: 10 }) {
            Text(this.imageUri ? '已选择药品图片' : '尚未选择图片').fontSize(13).fontColor('#718078')
            Blank()
            Button('选择图片').height(38).backgroundColor('#EAF4ED').fontColor('#287451')
              .onClick(() => this.chooseImage())
          }.width('100%').padding({ left: 12, right: 8, top: 6, bottom: 6 })
            .backgroundColor('#F6F8F6').borderRadius(12)
          Row({ space: 10 }) {
            Column() { this.field('数量', this.quantity, (v: string) => this.quantity = v, '1', InputType.Number) }.layoutWeight(1)
            Column() { this.field('备注', this.notes, (v: string) => this.notes = v, '可选') }.layoutWeight(1)
          }.width('100%')
          Button(this.editingId > 0 ? '保存修改' : '添加到药箱')
            .width('100%').height(46).backgroundColor('#287451').borderRadius(13)
            .fontSize(15).fontWeight(500).onClick(() => this.save())
        }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(18)

        Column({ space: 10 }) {
          Row() {
            Text('全部药品').fontSize(16).fontWeight(500).fontColor('#1D2B24')
            Blank()
            Text('效期由近到远').fontSize(12).fontColor('#718078')
          }.width('100%')
          if (this.visibleMedicines.length === 0) {
            Column({ space: 8 }) {
              Text('✳').fontSize(28).fontColor('#8DB5A0')
              Text(this.keyword || this.selectedCategory !== '全部' ? '没有找到匹配药品' : '药箱还是空的').fontSize(14).fontColor('#718078')
              Text(this.keyword || this.selectedCategory !== '全部' ? '试试其他名称或分类' : '添加第一条记录，开始整理家庭药箱').fontSize(12).fontColor('#9AA69F')
            }.width('100%').padding({ top: 26, bottom: 26 })
          } else {
            ForEach(this.visibleMedicines, (item: Medicine) => {
              Column({ space: 10 }) {
                Row() {
                  Column({ space: 5 }) {
                    Text(item.name).fontSize(16).fontWeight(500).fontColor('#1D2B24')
                    Text(`${item.category || '未分类'}  ·  数量 ${item.quantity}`).fontSize(12).fontColor('#718078')
                  }.alignItems(HorizontalAlign.Start)
                  Blank()
                  Text(item.expiryMonth).fontSize(12).fontWeight(FontWeight.Medium).fontColor('#287451')
                    .backgroundColor('#EAF4ED').padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(16)
                }.width('100%')
                if (item.notes) Text(item.notes).fontSize(12).fontColor('#7D8982').width('100%')
                Row({ space: 16 }) {
                  Text('编辑').fontSize(12).fontColor('#287451').onClick(() => this.edit(item))
                  Text('删除').fontSize(12).fontColor('#B44A43').onClick(() => this.confirmRemove(item))
                }.justifyContent(FlexAlign.End).width('100%')
              }.width('100%').padding(14).backgroundColor('#FAFBFA').borderRadius(14)
            }, (item: Medicine) => `${item.id}`)
          }
        }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(18)

        Text('数据仅保存在本机 · 当前版本不提供用药建议').fontSize(11).fontColor('#93A098')
          .width('100%').textAlign(TextAlign.Center).padding({ top: 2, bottom: 18 })
      }.padding({ left: 20, right: 20, top: 24, bottom: 20 }).width('100%')
    }.scrollBar(BarState.Off).backgroundColor('#F1F5F1').height('100%').width('100%')
  }
}


