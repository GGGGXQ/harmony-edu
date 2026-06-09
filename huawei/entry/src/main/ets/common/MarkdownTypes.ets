export class MdInline {
  type: string = 'text';
  text: string = '';
  href: string = '';
  title: string = '';
  children: MdInline[] = [];
}

export class MdListItem {
  text: string = '';
  spans: MdInline[] = [];
  subItems: MdListItem[] = [];
  taskChecked: boolean = false;
}

export class MdBlock {
  type: string = '';
  text: string = '';
  spans: MdInline[] = [];
  items: MdListItem[] = [];
  ordered: boolean = false;
  start: number = 1;
  lang: string = '';
  blocks: MdBlock[] = [];
  align: string[] = [];
}
