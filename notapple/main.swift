import Cocoa
import PDFKit

var isEN: Bool = UserDefaults.standard.string(forKey: "ui").map { $0 == "en" } ?? !(Locale.preferredLanguages.first ?? "").hasPrefix("zh")
let enStr: [String: String] = [
  "未命名": "Untitled",
  "CR (旧 Mac)": "CR (classic Mac)",
  "PDF(只读预览)": "PDF (read-only preview)",
  "无法作为文本打开:%@": "Can't open as text: %@",
  "文件看起来是二进制。": "This file looks like binary data.",
  "文本": "Text",
  "纯文本": "Plain Text",
  "行 %ld, 列 %ld  |  %ld 字符  |  %@  |  %@  |  %@": "Ln %ld, Col %ld  |  %ld chars  |  %@  |  %@  |  %@",
  "保存对“%@”的更改?": "Save changes to “%@”?",
  "保存": "Save",
  "不保存": "Don't Save",
  "取消": "Cancel",
  "查找 / 替换": "Find / Replace",
  "查找": "Find",
  "替换为": "Replace with",
  "正则表达式": "Regular expression",
  "区分大小写": "Match case",
  "查找下一个": "Find Next",
  "替换": "Replace",
  "全部替换": "Replace All",
  "已替换 %ld 处": "%ld replaced",
  "有未保存的更改,仍要退出?": "You have unsaved changes. Quit anyway?",
  "退出": "Quit",
  "退出 notapple": "Quit notapple",
  "文件": "File",
  "新建标签页": "New Tab",
  "打开…": "Open…",
  "打开文件夹…": "Open Folder…",
  "关闭文件夹": "Close Folder",
  "另存为…": "Save As…",
  "关闭标签页": "Close Tab",
  "编辑": "Edit",
  "撤销": "Undo",
  "重做": "Redo",
  "剪切": "Cut",
  "拷贝": "Copy",
  "粘贴": "Paste",
  "全选": "Select All",
  "查找 / 替换…": "Find / Replace…",
  "跳转到行…": "Go to Line…",
  "跳转到行": "Go to Line",
  "跳转": "Go",
  "复制当前行": "Duplicate Line",
  "删除当前行": "Delete Line",
  "上移一行": "Move Line Up",
  "下移一行": "Move Line Down",
  "切换行注释": "Toggle Comment",
  "转大写": "Uppercase",
  "转小写": "Lowercase",
  "行排序": "Sort Lines",
  "删除重复行": "Remove Duplicate Lines",
  "去除行尾空白": "Trim Trailing Spaces",
  "换行符": "Line Endings",
  "换行符转换": "Convert Line Endings",
  "视图": "View",
  "自动换行": "Word Wrap",
  "放大": "Zoom In",
  "缩小": "Zoom Out",
  "编码": "Encoding",
  "以 %@ 保存": "Save as %@",
  "语法高亮": "Syntax",
  "界面语言": "Interface Language",
  "窗口": "Window",
  "下一个标签页": "Next Tab",
  "上一个标签页": "Previous Tab"]
func T(_ s: String) -> String { isEN ? (enStr[s] ?? s) : s }

// MARK: 语言表(正则高亮,按扩展名匹配)
final class Lang {
  let name: String, exts: [String], kw: String, lc: String?, bc: String?, ci: Bool, str: Bool, x: [(String, NSColor)]
  init(_ n: String, _ e: String, _ k: String, lc: String? = "//", bc: String? = #"/\*[\s\S]*?\*/"#,
       ci: Bool = false, str: Bool = true, x: [(String, NSColor)] = []) {
    name = n; exts = e.split(separator: " ").map(String.init); kw = k
    self.lc = lc; self.bc = bc; self.ci = ci; self.str = str; self.x = x
  }
  lazy var rules: [(NSRegularExpression, NSColor)] = {
    var p = x
    if !kw.isEmpty { p.append((#"\b(?:"# + kw.split(separator: " ").joined(separator: "|") + #")\b"#, .systemPink)) }
    if str {
      p.append((#"\b(?:0x[0-9A-Fa-f]+|\d+\.?\d*)\b"#, .systemOrange))
      p.append((#""(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'"#, .systemRed))
    }
    if let l = lc { p.append((NSRegularExpression.escapedPattern(for: l) + ".*$", .systemGreen)) }
    if let b = bc { p.append((b, .systemGreen)) }
    let o: NSRegularExpression.Options = ci ? [.anchorsMatchLines, .caseInsensitive] : [.anchorsMatchLines]
    return p.compactMap { r in (try? NSRegularExpression(pattern: r.0, options: o)).map { ($0, r.1) } }
  }()
}
let cKW = "if else for while do switch case default break continue return goto sizeof struct union enum typedef static const extern void int char long short float double unsigned signed class public private protected virtual template namespace using new delete this try catch throw nullptr true false auto bool inline"
let langs: [Lang] = [
  Lang("Swift", "swift", "func let var class struct enum protocol extension import if else guard return for while switch case default in do try catch throw self nil true false init public private static final override where as is async await"),
  Lang("C/C++/ObjC", "c h cpp cc cxx hpp hh m mm ino", cKW, x: [(#"^\s*#\s*\w+.*$"#, .systemPurple)]),
  Lang("Java/Kotlin/C#", "java kt kts cs scala", cKW + " fun val var package import interface extends implements final abstract override string object internal"),
  Lang("JavaScript/TS", "js jsx mjs ts tsx", "function var let const if else for while do switch case default break continue return class extends new this try catch throw import export from async await typeof null undefined true false interface type enum"),
  Lang("Python", "py pyw", "def class if elif else for while return import from as with try except finally raise lambda yield pass break continue in is not and or None True False global async await", lc: "#", bc: #"""[\s\S]*?"""|'''[\s\S]*?'''"#),
  Lang("Go", "go", "func var const type struct interface map chan package import if else for range switch case default return break continue go defer select nil true false"),
  Lang("Rust", "rs", "fn let mut const static struct enum impl trait pub use mod crate self super if else match for while loop return break continue as ref move async await true false where type"),
  Lang("Shell", "sh bash zsh fish", "if then else elif fi for while do done case esac function in return export local echo exit", lc: "#", bc: nil),
  Lang("Ruby", "rb", "def class module if elsif else end unless while for do return yield begin rescue ensure nil true false self require", lc: "#", bc: nil),
  Lang("PHP", "php", "function class if else elseif foreach for while switch case return echo new public private protected static null true false namespace use", lc: "//"),
  Lang("HTML/XML", "html htm xml svg plist xhtml", "", lc: nil, bc: #"<!--[\s\S]*?-->"#, str: false,
       x: [(#"</?[A-Za-z!][^>]*>"#, .systemBlue), (#""[^"\n]*""#, .systemRed)]),
  Lang("CSS", "css scss less", "", lc: nil, x: [(#"[a-z-]+(?=\s*:)"#, .systemBlue)]),
  Lang("JSON", "json", "true false null", lc: nil, bc: nil),
  Lang("YAML/INI/TOML", "yml yaml toml ini conf cfg", "true false null yes no", lc: "#", bc: nil, x: [(#"^\s*\[[^\]]+\]|^[\w.-]+(?=\s*[:=])"#, .systemBlue)]),
  Lang("SQL", "sql", "select from where insert into values update set delete create table drop alter join left right inner outer on group by order having limit as and or not null is in like distinct union primary key", lc: "--", ci: true),
  Lang("Lua", "lua", "function local if then else elseif end for while do return nil true false in and or not repeat until", lc: "--", bc: #"--\[\[[\s\S]*?\]\]"#),
  Lang("Markdown", "md markdown", "", lc: nil, bc: nil, str: false,
       x: [(#"^#{1,6} .*$"#, .systemBlue), (#"\*\*[^*\n]+\*\*"#, .systemOrange), (#"`[^`\n]+`"#, .systemGreen),
           (#"\[[^\]\n]*\]\([^)\n]*\)"#, .systemPurple), (#"^\s*(?:[-*+]|\d+\.) "#, .systemPink)]),
  Lang("Verilog/SV", "v sv svh vh", "module endmodule input output inout wire reg logic always assign begin end if else case endcase for while initial posedge negedge parameter localparam function endfunction task endtask generate endgenerate integer"),
  Lang("VHDL", "vhd vhdl", "library use entity architecture is of begin end port map signal variable process if then else elsif case when for loop in out inout std_logic std_logic_vector generic component", lc: "--", bc: nil, ci: true),
  Lang("Assembly", "s asm", "mov add sub mul div push pop call ret jmp je jne cmp lea nop int ldr str bl b mrs msr", lc: ";", bc: nil, ci: true),
  Lang("Tcl/XDC", "tcl xdc sdc", "set proc if else foreach while return puts source create_clock set_property", lc: "#", bc: nil),
]
func detect(_ u: URL) -> Lang? { let e = u.pathExtension.lowercased(); return langs.first { $0.exts.contains(e) } }

// MARK: 编码
func cf(_ e: CFStringEncodings) -> String.Encoding { .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(e.rawValue))) }
let encs: [(String, String.Encoding, Bool)] = [("UTF-8", .utf8, false), ("UTF-8 BOM", .utf8, true), ("UTF-16", .utf16, false),
  ("GB18030", cf(.GB_18030_2000), false), ("Big5", cf(.big5), false), ("Shift-JIS", .shiftJIS, false), ("Latin-1", .isoLatin1, false)]
func decode(_ d: Data) -> (String, String.Encoding, Bool)? {
  if d.starts(with: [0xEF, 0xBB, 0xBF]), let s = String(data: d.dropFirst(3), encoding: .utf8) { return (s, .utf8, true) }
  if d.starts(with: [0xFF, 0xFE]) || d.starts(with: [0xFE, 0xFF]), let s = String(data: d, encoding: .utf16) { return (s, .utf16, false) }
  if d.prefix(8000).contains(0) { return nil }
  if let s = String(data: d, encoding: .utf8) { return (s, .utf8, false) }
  for e in [cf(.GB_18030_2000), .shiftJIS, cf(.big5), .isoLatin1] { if let s = String(data: d, encoding: e) { return (s, e, false) } }
  return nil
}

// MARK: 行号栏
final class Gutter: NSRulerView {
  weak var tv: NSTextView?
  init(_ s: NSScrollView, _ t: NSTextView) {
    tv = t; super.init(scrollView: s, orientation: .verticalRuler); clientView = t; ruleThickness = 46
    s.contentView.postsBoundsChangedNotifications = true
    NotificationCenter.default.addObserver(self, selector: #selector(redraw), name: NSText.didChangeNotification, object: t)
    NotificationCenter.default.addObserver(self, selector: #selector(redraw), name: NSView.boundsDidChangeNotification, object: s.contentView)
  }
  required init(coder: NSCoder) { fatalError() }
  @objc func redraw() { needsDisplay = true }
  override func drawHashMarksAndLabels(in rect: NSRect) {
    NSColor.controlBackgroundColor.setFill(); bounds.fill()
    guard let tv = tv, let lm = tv.layoutManager, let tc = tv.textContainer else { return }
    let s = tv.string as NSString
    let g = lm.glyphRange(forBoundingRect: tv.visibleRect, in: tc)
    var i = lm.characterRange(forGlyphRange: g, actualGlyphRange: nil).location
    let end = NSMaxRange(lm.characterRange(forGlyphRange: g, actualGlyphRange: nil))
    var n = 1; for u in s.substring(to: i).utf16 where u == 10 { n += 1 }
    let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular), .foregroundColor: NSColor.secondaryLabelColor]
    i = s.lineRange(for: NSRange(location: i, length: 0)).location
    while i <= end && s.length > 0 {
      let gi = lm.glyphIndexForCharacter(at: min(i, s.length - 1))
      let r = lm.lineFragmentRect(forGlyphAt: gi, effectiveRange: nil)
      let p = convert(NSPoint(x: 0, y: r.minY + tv.textContainerOrigin.y), from: tv)
      let t = "\(n)" as NSString; t.draw(at: NSPoint(x: ruleThickness - 6 - t.size(withAttributes: a).width, y: p.y), withAttributes: a)
      let nx = NSMaxRange(s.lineRange(for: NSRange(location: i, length: 0))); if nx >= s.length || nx == i { break }
      i = nx; n += 1
    }
  }
}

// MARK: 文件夹侧边栏
final class Node {
  let url: URL, isDir: Bool
  init(_ u: URL) { url = u; isDir = (try? u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
  lazy var kids: [Node] = {
    let u = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)) ?? []
    return u.map { Node($0) }.sorted { $0.isDir != $1.isDir ? $0.isDir : $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending }
  }()
}
final class Sidebar: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
  let view = NSScrollView(), ov = NSOutlineView()
  var top: [Node] = []
  var root: URL? { didSet { top = root.map { Node($0).kids } ?? []; ov.reloadData() } }
  override init() {
    super.init()
    let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("n")); ov.addTableColumn(c); ov.outlineTableColumn = c
    ov.headerView = nil; ov.style = .sourceList; ov.dataSource = self; ov.delegate = self; ov.target = self; ov.doubleAction = #selector(dbl)
    view.documentView = ov; view.hasVerticalScroller = true
  }
  func outlineView(_ o: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int { item == nil ? top.count : (item as! Node).kids.count }
  func outlineView(_ o: NSOutlineView, child index: Int, ofItem item: Any?) -> Any { item == nil ? top[index] : (item as! Node).kids[index] }
  func outlineView(_ o: NSOutlineView, isItemExpandable item: Any) -> Bool { (item as! Node).isDir }
  func outlineView(_ o: NSOutlineView, viewFor c: NSTableColumn?, item: Any) -> NSView? {
    let n = item as! Node, t = NSTextField(labelWithString: n.url.lastPathComponent)
    t.lineBreakMode = .byTruncatingMiddle; t.font = .systemFont(ofSize: 12, weight: n.isDir ? .semibold : .regular); return t
  }
  @objc func dbl() {
    guard let n = ov.item(atRow: ov.clickedRow) as? Node else { return }
    if n.isDir { ov.isItemExpanded(n) ? ov.collapseItem(n) : ov.expandItem(n) } else { (NSApp.delegate as? App)?.openURL(n.url) }
  }
}

// MARK: 文档(每个标签页一个)
var docs: [Doc] = []
var folderRoot: URL?
func cur() -> Doc? { docs.first { $0.win == NSApp.mainWindow } ?? docs.last }

final class Doc: NSObject, NSWindowDelegate, NSTextViewDelegate {
  let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 680), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
  let scroll = NSTextView.scrollableTextView()
  let status = NSTextField(labelWithString: "")
  let split = NSSplitView(), area = NSView(), side = Sidebar()
  var tv: NSTextView { scroll.documentView as! NSTextView }
  var url: URL?, enc = String.Encoding.utf8, bom = false, lang: Lang?, size: CGFloat = 13, wrap = true, eol = "LF"
  var work: DispatchWorkItem?

  init(_ u: URL?) {
    super.init()
    win.title = T("未命名"); win.tabbingMode = .preferred; win.tabbingIdentifier = "ed"; win.isReleasedWhenClosed = false; win.delegate = self
    let t = tv
    t.isRichText = false; t.allowsUndo = true; t.delegate = self; t.textContainerInset = NSSize(width: 4, height: 6)
    t.isAutomaticQuoteSubstitutionEnabled = false; t.isAutomaticDashSubstitutionEnabled = false
    t.isAutomaticSpellingCorrectionEnabled = false; t.isAutomaticTextReplacementEnabled = false
    setSize(13)
    scroll.hasVerticalRuler = true; scroll.rulersVisible = true; scroll.verticalRulerView = Gutter(scroll, t)
    status.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular); status.textColor = .secondaryLabelColor
    let root = NSView(); win.contentView = root
    split.isVertical = true; split.dividerStyle = .thin
    scroll.translatesAutoresizingMaskIntoConstraints = false; area.addSubview(scroll)
    split.addArrangedSubview(side.view); split.addArrangedSubview(area); side.view.isHidden = true
    split.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
    for v in [split, status] { v.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(v) }
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: area.topAnchor), scroll.leadingAnchor.constraint(equalTo: area.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: area.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: area.bottomAnchor),
      split.topAnchor.constraint(equalTo: root.topAnchor), split.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      split.trailingAnchor.constraint(equalTo: root.trailingAnchor), split.bottomAnchor.constraint(equalTo: status.topAnchor, constant: -3),
      status.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10), status.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      status.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -4)])
    docs.append(self)
    if let k = cur(), k !== self, docs.count > 1 { docs[docs.count - 2].win.addTabbedWindow(win, ordered: .above) }
    win.makeKeyAndOrderFront(nil); updateSidebar()
    if let u = u { load(u) } else { refresh() }
  }
  func updateSidebar() {
    guard let r = folderRoot else { side.view.isHidden = true; split.adjustSubviews(); return }
    let was = side.view.isHidden; side.root = r; side.view.isHidden = false; split.adjustSubviews()
    if was { split.setPosition(220, ofDividerAt: 0) }
  }
  func setSize(_ s: CGFloat) { size = max(8, min(48, s)); tv.font = .monospacedSystemFont(ofSize: size, weight: .regular); highlight() }
  func setWrap(_ w: Bool) {
    wrap = w; scroll.hasHorizontalScroller = !w; tv.isHorizontallyResizable = !w
    tv.textContainer?.widthTracksTextView = w
    tv.textContainer?.size = NSSize(width: w ? scroll.contentSize.width : 1e7, height: 1e7)
    if !w { tv.maxSize = NSSize(width: 1e7, height: 1e7) } else { tv.frame.size.width = scroll.contentSize.width }
  }
  func load(_ u: URL) {
    guard let d = try? Data(contentsOf: u) else { return }
    url = u; win.title = u.lastPathComponent; win.representedURL = u
    NSDocumentController.shared.noteNewRecentDocumentURL(u)
    if u.pathExtension.lowercased() == "pdf" {
      let p = PDFView(); p.document = PDFDocument(url: u); p.autoScales = true
      p.translatesAutoresizingMaskIntoConstraints = false; scroll.isHidden = true; status.stringValue = T("PDF(只读预览)")
      area.addSubview(p)
      NSLayoutConstraint.activate([p.topAnchor.constraint(equalTo: area.topAnchor), p.leadingAnchor.constraint(equalTo: area.leadingAnchor),
        p.trailingAnchor.constraint(equalTo: area.trailingAnchor), p.bottomAnchor.constraint(equalTo: area.bottomAnchor)])
      return
    }
    guard let (s, e, b) = decode(d) else {
      let a = NSAlert(); a.messageText = String(format: T("无法作为文本打开:%@"), u.lastPathComponent); a.informativeText = T("文件看起来是二进制。"); a.runModal(); win.close(); return
    }
    enc = e; bom = b; eol = s.contains("\r\n") ? "CRLF" : (s.contains("\r") ? "CR" : "LF")
    tv.string = s; lang = detect(u); highlight(); win.isDocumentEdited = false; refresh()
  }
  func save(_ asNew: Bool) {
    var u = url
    if u == nil || asNew { let p = NSSavePanel(); guard p.runModal() == .OK else { return }; u = p.url }
    guard let t = u else { return }
    var d = tv.string.data(using: enc, allowLossyConversion: false) ?? Data()
    if bom && enc == .utf8 { d = Data([0xEF, 0xBB, 0xBF]) + d }
    do { try d.write(to: t, options: .atomic) } catch { NSAlert(error: error).runModal(); return }
    url = t; win.title = t.lastPathComponent; win.representedURL = t; win.isDocumentEdited = false
    lang = detect(t); highlight(); refresh()
  }
  func edit(_ r: NSRange, _ s: String) {
    if tv.shouldChangeText(in: r, replacementString: s) { tv.textStorage?.replaceCharacters(in: r, with: s); tv.didChangeText() }
  }
  func highlight() {
    guard let lm = tv.layoutManager else { return }
    let s = tv.string, full = NSRange(location: 0, length: (s as NSString).length)
    lm.removeTemporaryAttribute(.foregroundColor, forCharacterRange: full)
    guard let l = lang, full.length < 1_500_000 else { return }
    for (re, c) in l.rules { re.enumerateMatches(in: s, range: full) { m, _, _ in
      if let r = m?.range { lm.addTemporaryAttribute(.foregroundColor, value: c, forCharacterRange: r) } } }
  }
  func refresh() {
    let s = tv.string as NSString, p = tv.selectedRange().location
    var ln = 1, last = 0, i = 0
    for u in s.substring(to: min(p, s.length)).utf16 { i += 1; if u == 10 { ln += 1; last = i } }
    let encName = encs.first { $0.1 == enc && $0.2 == bom }?.0 ?? T("文本")
    status.stringValue = String(format: T("行 %ld, 列 %ld  |  %ld 字符  |  %@  |  %@  |  %@"), ln, p - last + 1, s.length, lang?.name ?? T("纯文本"), encName, eol)
  }
  func textDidChange(_ n: Notification) {
    win.isDocumentEdited = true; refresh(); work?.cancel()
    let w = DispatchWorkItem { [weak self] in self?.highlight() }; work = w
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: w)
  }
  func textViewDidChangeSelection(_ n: Notification) { refresh() }
  func textView(_ t: NSTextView, doCommandBy sel: Selector) -> Bool {   // 自动缩进
    guard sel == #selector(NSResponder.insertNewline(_:)) else { return false }
    let s = t.string as NSString, lr = s.lineRange(for: NSRange(location: t.selectedRange().location, length: 0))
    let ind = String(s.substring(with: lr).prefix { $0 == " " || $0 == "\t" })
    t.insertText("\n" + ind, replacementRange: t.selectedRange()); return true
  }
  func windowShouldClose(_ s: NSWindow) -> Bool {
    guard s.isDocumentEdited else { return true }
    let a = NSAlert(); a.messageText = String(format: T("保存对“%@”的更改?"), s.title)
    a.addButton(withTitle: T("保存")); a.addButton(withTitle: T("不保存")); a.addButton(withTitle: T("取消"))
    switch a.runModal() {
    case .alertFirstButtonReturn: save(false); return !s.isDocumentEdited
    case .alertSecondButtonReturn: return true
    default: return false }
  }
  func windowWillClose(_ n: Notification) { docs.removeAll { $0 === self } }
}

// MARK: 查找/替换(支持正则)
final class Finder: NSObject {
  static let shared = Finder()
  let panel = NSPanel(contentRect: .zero, styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
  let f = NSTextField(), r = NSTextField()
  var btns: [NSButton] = []
  let rx = NSButton(checkboxWithTitle: T("正则表达式"), target: nil, action: nil), cs = NSButton(checkboxWithTitle: T("区分大小写"), target: nil, action: nil)
  override init() {
    super.init(); panel.title = T("查找 / 替换"); f.placeholderString = T("查找"); r.placeholderString = T("替换为")
    let b = [(T("查找下一个"), #selector(next)), (T("替换"), #selector(rep)), (T("全部替换"), #selector(all))].map { NSButton(title: $0.0, target: self, action: $0.1) }
    btns = b
    let st = NSStackView(views: [f, r, NSStackView(views: [rx, cs]), NSStackView(views: b)])
    st.orientation = .vertical; st.alignment = .leading; st.spacing = 8; st.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    f.widthAnchor.constraint(equalToConstant: 340).isActive = true; r.widthAnchor.constraint(equalToConstant: 340).isActive = true
    panel.contentView = st; panel.setContentSize(st.fittingSize)
  }
  func localize() {
    panel.title = T("查找 / 替换"); f.placeholderString = T("查找"); r.placeholderString = T("替换为")
    rx.title = T("正则表达式"); cs.title = T("区分大小写")
    for (i, t) in [T("查找下一个"), T("替换"), T("全部替换")].enumerated() { btns[i].title = T(t) }
  }
  func show() { panel.makeKeyAndOrderFront(nil); panel.makeFirstResponder(f) }
  func re() -> NSRegularExpression? {
    let p = rx.state == .on ? f.stringValue : NSRegularExpression.escapedPattern(for: f.stringValue)
    return try? NSRegularExpression(pattern: p, options: cs.state == .on ? [.anchorsMatchLines] : [.anchorsMatchLines, .caseInsensitive])
  }
  var tpl: String { rx.state == .on ? r.stringValue : NSRegularExpression.escapedTemplate(for: r.stringValue) }
  @objc func next() {
    guard let d = cur(), let e = re(), !f.stringValue.isEmpty else { return }
    let s = d.tv.string, n = (s as NSString).length, from = NSMaxRange(d.tv.selectedRange())
    let m = e.firstMatch(in: s, range: NSRange(location: from, length: n - from)) ?? e.firstMatch(in: s, range: NSRange(location: 0, length: n))
    guard let rg = m?.range else { NSSound.beep(); return }
    d.tv.setSelectedRange(rg); d.tv.scrollRangeToVisible(rg); d.tv.showFindIndicator(for: rg)
  }
  @objc func rep() {
    guard let d = cur(), let e = re() else { return }
    let s = d.tv.string as NSString, sel = d.tv.selectedRange()
    if let m = e.firstMatch(in: s as String, range: sel), m.range == sel { d.edit(sel, e.replacementString(for: m, in: s as String, offset: 0, template: tpl)) }
    next()
  }
  @objc func all() {
    guard let d = cur(), let e = re() else { return }
    let s = d.tv.string, n = e.numberOfMatches(in: s, range: NSRange(location: 0, length: (s as NSString).length))
    d.edit(NSRange(location: 0, length: (s as NSString).length), e.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: (s as NSString).length), withTemplate: tpl))
    panel.title = String(format: T("已替换 %ld 处"), n)
  }
}

// MARK: 图标(原创,代码绘制;build.sh 调用 --make-icon 生成 .icns)
func drawIcon() {
  let teal = NSColor(calibratedRed: 0.10, green: 0.55, blue: 0.48, alpha: 1)
  NSGradient(starting: teal, ending: NSColor(calibratedRed: 0.05, green: 0.22, blue: 0.30, alpha: 1))!
    .draw(in: NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 448, height: 448), xRadius: 100, yRadius: 100), angle: -90)
  NSColor.white.withAlphaComponent(0.96).setFill()
  NSBezierPath(roundedRect: NSRect(x: 138, y: 92, width: 236, height: 328), xRadius: 26, yRadius: 26).fill()
  for (i, w) in [150, 110, 150, 80].enumerated() {
    teal.withAlphaComponent(i == 1 ? 0.45 : 0.9).setFill()
    NSBezierPath(roundedRect: NSRect(x: 172, y: 360 - CGFloat(i) * 56, width: CGFloat(w), height: 22), xRadius: 11, yRadius: 11).fill() }
  NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.25, alpha: 1).setFill()
  NSBezierPath(ovalIn: NSRect(x: 300, y: 112, width: 44, height: 44)).fill()
}
func writeIconset(_ dir: String) {
  try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
  for (n, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128), ("128x128@2x", 256),
                  ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                                     hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else { continue }
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ctx
    ctx.cgContext.scaleBy(x: CGFloat(px) / 512, y: CGFloat(px) / 512); drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "\(dir)/icon_\(n).png"))
  }
}

// MARK: 应用与菜单
final class App: NSObject, NSApplicationDelegate {
  func openURL(_ u: URL) {
    if let d = docs.first(where: { $0.url == u }) { d.win.makeKeyAndOrderFront(nil); return }
    if let c = cur(), c.url == nil, !c.win.isDocumentEdited, c.tv.string.isEmpty { c.load(u) } else { _ = Doc(u) }
  }
  func application(_ a: NSApplication, openFiles f: [String]) { f.forEach { openURL(URL(fileURLWithPath: $0)) }; a.reply(toOpenOrPrint: .success) }
  func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { true }
  func applicationShouldTerminate(_ a: NSApplication) -> NSApplication.TerminateReply {
    guard docs.contains(where: { $0.win.isDocumentEdited }) else { return .terminateNow }
    let al = NSAlert(); al.messageText = T("有未保存的更改,仍要退出?"); al.addButton(withTitle: T("取消")); al.addButton(withTitle: T("退出"))
    return al.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
  }
  func applicationDidFinishLaunching(_ n: Notification) {
    buildMenu(); if docs.isEmpty { _ = Doc(nil) }
  }
  func add(_ m: NSMenu, _ t: String, _ a: Selector?, _ k: String = "", _ mod: NSEvent.ModifierFlags = .command, tag: Int = 0) {
    let i = m.addItem(withTitle: t, action: a, keyEquivalent: k); i.keyEquivalentModifierMask = mod; i.tag = tag
  }
  func sub(_ title: String) -> NSMenu {
    let m = NSMenu(title: title), i = NSMenuItem(); i.submenu = m; NSApp.mainMenu!.addItem(i); return m
  }
  func buildMenu() {
    NSApp.mainMenu = NSMenu()
    let a = sub("notapple"); add(a, T("退出 notapple"), #selector(NSApplication.terminate(_:)), "q")
    let f = sub(T("文件"))
    add(f, T("新建标签页"), #selector(newDoc), "n"); add(f, T("打开…"), #selector(openDlg), "o"); add(f, T("打开文件夹…"), #selector(openFolder), "o", [.command, .shift]); add(f, T("关闭文件夹"), #selector(closeFolder)); add(f, T("保存"), #selector(save), "s")
    add(f, T("另存为…"), #selector(saveAs), "s", [.command, .shift]); add(f, T("关闭标签页"), #selector(NSWindow.performClose(_:)), "w")
    let e = sub(T("编辑"))
    add(e, T("撤销"), Selector(("undo:")), "z"); add(e, T("重做"), Selector(("redo:")), "z", [.command, .shift])
    add(e, T("剪切"), #selector(NSText.cut(_:)), "x"); add(e, T("拷贝"), #selector(NSText.copy(_:)), "c")
    add(e, T("粘贴"), #selector(NSText.paste(_:)), "v"); add(e, T("全选"), #selector(NSText.selectAll(_:)), "a")
    e.addItem(.separator())
    add(e, T("查找 / 替换…"), #selector(find), "f"); add(e, T("查找下一个"), #selector(findNext), "g"); add(e, T("跳转到行…"), #selector(goLine), "l")
    e.addItem(.separator())
    add(e, T("复制当前行"), #selector(dup), "d"); add(e, T("删除当前行"), #selector(delLine), "k", [.command, .shift])
    add(e, T("上移一行"), #selector(up), String(UnicodeScalar(NSUpArrowFunctionKey)!), [.control, .shift])
    add(e, T("下移一行"), #selector(down), String(UnicodeScalar(NSDownArrowFunctionKey)!), [.control, .shift])
    add(e, T("切换行注释"), #selector(comment), "/")
    add(e, T("转大写"), #selector(upper), "u", [.command, .shift]); add(e, T("转小写"), #selector(lower), "u", [.command, .option])
    add(e, T("行排序"), #selector(sortL)); add(e, T("删除重复行"), #selector(dedupe)); add(e, T("去除行尾空白"), #selector(trim))
    let el = NSMenu(title: T("换行符")); let eli = e.addItem(withTitle: T("换行符转换"), action: nil, keyEquivalent: ""); eli.submenu = el
    for (i, t) in ["LF (Unix)", "CRLF (Windows)", T("CR (旧 Mac)")].enumerated() { add(el, t, #selector(setEOL(_:)), "", [], tag: i) }
    let v = sub(T("视图"))
    add(v, T("自动换行"), #selector(toggleWrap), "w", [.option]); add(v, T("放大"), #selector(bigger), "+"); add(v, T("缩小"), #selector(smaller), "-")
    let en = sub(T("编码")); for (i, x) in encs.enumerated() { add(en, String(format: T("以 %@ 保存"), x.0), #selector(setEnc(_:)), "", [], tag: i) }
    let lg = sub(T("语法高亮")); add(lg, T("纯文本"), #selector(setLang(_:)), "", [], tag: -1)
    for (i, l) in langs.enumerated() { add(lg, l.name, #selector(setLang(_:)), "", [], tag: i) }
    let ui = sub(T("界面语言")); add(ui, T("中文"), #selector(setUI(_:)), "", [], tag: 0); add(ui, "English", #selector(setUI(_:)), "", [], tag: 1)
    ui.items[0].state = isEN ? .off : .on; ui.items[1].state = isEN ? .on : .off
    let w = sub(T("窗口")); NSApp.windowsMenu = w
    add(w, T("下一个标签页"), #selector(NSWindow.selectNextTab(_:)), "\t", .control); add(w, T("上一个标签页"), #selector(NSWindow.selectPreviousTab(_:)), "\t", [.control, .shift])
  }
  @objc func openFolder() {
    let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false
    if p.runModal() == .OK { folderRoot = p.url; docs.forEach { $0.updateSidebar() } }
  }
  @objc func closeFolder() { folderRoot = nil; docs.forEach { $0.updateSidebar() } }
  @objc func setUI(_ i: NSMenuItem) {
    isEN = i.tag == 1; UserDefaults.standard.set(isEN ? "en" : "zh", forKey: "ui"); buildMenu()
    for d in docs { if d.url == nil { d.win.title = T("未命名") }; d.refresh() }
    Finder.shared.localize()
  }
  @objc func newDoc() { _ = Doc(nil) }
  @objc func openDlg() { let p = NSOpenPanel(); p.allowsMultipleSelection = true; if p.runModal() == .OK { p.urls.forEach(openURL) } }
  @objc func save() { cur()?.save(false) }
  @objc func saveAs() { cur()?.save(true) }
  @objc func find() { Finder.shared.show() }
  @objc func findNext() { Finder.shared.next() }
  @objc func goLine() {
    guard let d = cur() else { return }
    let a = NSAlert(); a.messageText = T("跳转到行"); let t = NSTextField(frame: NSRect(x: 0, y: 0, width: 120, height: 24)); a.accessoryView = t
    a.addButton(withTitle: T("跳转")); a.addButton(withTitle: T("取消")); a.window.initialFirstResponder = t
    guard a.runModal() == .alertFirstButtonReturn, let n = Int(t.stringValue) else { return }
    let s = d.tv.string as NSString; var i = 0
    for _ in 1..<max(n, 1) { let nx = NSMaxRange(s.lineRange(for: NSRange(location: i, length: 0))); if nx >= s.length { break }; i = nx }
    d.tv.setSelectedRange(NSRange(location: i, length: 0)); d.tv.scrollRangeToVisible(NSRange(location: i, length: 0)); d.win.makeFirstResponder(d.tv)
  }
  func lines(_ d: Doc) -> (NSString, NSRange) { let s = d.tv.string as NSString; return (s, s.lineRange(for: d.tv.selectedRange())) }
  @objc func dup() { guard let d = cur() else { return }; let (s, r) = lines(d); var t = s.substring(with: r); if !t.hasSuffix("\n") { t = "\n" + t }; d.edit(NSRange(location: NSMaxRange(r), length: 0), t) }
  @objc func delLine() { guard let d = cur() else { return }; d.edit(lines(d).1, "") }
  @objc func up() { move(-1) }
  @objc func down() { move(1) }
  func move(_ k: Int) {
    guard let d = cur() else { return }; let (s, r) = lines(d); let o: NSRange
    if k < 0 { guard r.location > 0 else { return }; o = s.lineRange(for: NSRange(location: r.location - 1, length: 0)) }
    else { guard NSMaxRange(r) < s.length else { return }; o = s.lineRange(for: NSRange(location: NSMaxRange(r), length: 0)) }
    let (a, b) = k < 0 ? (o, r) : (r, o)
    var x = s.substring(with: a), y = s.substring(with: b)
    if !y.hasSuffix("\n") { y += "\n"; x.removeLast() }
    d.edit(NSUnionRange(a, b), y + x)
    d.tv.setSelectedRange(k < 0 ? NSRange(location: a.location, length: y.utf16.count) : NSRange(location: a.location + y.utf16.count, length: x.utf16.count))
  }
  @objc func comment() {
    guard let d = cur() else { return }; let p = d.lang?.lc ?? "#"; let (s, r) = lines(d)
    let ls = s.substring(with: r).components(separatedBy: "\n")
    let ne = ls.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    let on = !ne.isEmpty && ne.allSatisfy { $0.trimmingCharacters(in: .whitespaces).hasPrefix(p) }
    d.edit(r, ls.map { l in
      if l.trimmingCharacters(in: .whitespaces).isEmpty { return l }
      if on, let g = l.range(of: p) { var n = l; n.removeSubrange(g); if g.lowerBound < n.endIndex && n[g.lowerBound] == " " { n.remove(at: g.lowerBound) }; return n }
      return p + " " + l }.joined(separator: "\n"))
  }
  func xf(_ f: (String) -> String) {
    guard let d = cur() else { return }; var r = d.tv.selectedRange(); let s = d.tv.string as NSString
    if r.length == 0 { r = NSRange(location: 0, length: s.length) }
    d.edit(r, f(s.substring(with: r)))
  }
  @objc func upper() { xf { $0.uppercased() } }
  @objc func lower() { xf { $0.lowercased() } }
  @objc func sortL() { xf { $0.components(separatedBy: "\n").sorted().joined(separator: "\n") } }
  @objc func dedupe() { xf { var seen = Set<String>(); return $0.components(separatedBy: "\n").filter { seen.insert($0).inserted }.joined(separator: "\n") } }
  @objc func trim() { xf { $0.components(separatedBy: "\n").map { l in l.replacingOccurrences(of: #"[ \t]+$"#, with: "", options: .regularExpression) }.joined(separator: "\n") } }
  @objc func setEOL(_ i: NSMenuItem) {
    guard let d = cur() else { return }; let e = ["\n", "\r\n", "\r"][i.tag]; let s = d.tv.string
    d.edit(NSRange(location: 0, length: (s as NSString).length), s.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n").replacingOccurrences(of: "\n", with: e))
    d.eol = ["LF", "CRLF", "CR"][i.tag]; d.refresh()
  }
  @objc func setEnc(_ i: NSMenuItem) { guard let d = cur() else { return }; d.enc = encs[i.tag].1; d.bom = encs[i.tag].2; d.win.isDocumentEdited = true; d.refresh() }
  @objc func setLang(_ i: NSMenuItem) { guard let d = cur() else { return }; d.lang = i.tag < 0 ? nil : langs[i.tag]; d.highlight(); d.refresh() }
  @objc func toggleWrap() { guard let d = cur() else { return }; d.setWrap(!d.wrap) }
  @objc func bigger() { if let d = cur() { d.setSize(d.size + 1) } }
  @objc func smaller() { if let d = cur() { d.setSize(d.size - 1) } }
}

if CommandLine.arguments.count > 2, CommandLine.arguments[1] == "--make-icon" { _ = NSApplication.shared; writeIconset(CommandLine.arguments[2]); exit(0) }
let app = NSApplication.shared; let delegate = App()
app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
