import Cocoa
import PDFKit
import WebKit
import Security

var isEN: Bool = UserDefaults.standard.string(forKey: "ui").map { $0 == "en" } ?? !(Locale.preferredLanguages.first ?? "").hasPrefix("zh")
let enStr: [String: String] = [
  "未命名": "Untitled",
  "语言已切换": "Language Changed",
  "“窗口”等系统菜单需要重启后才会切换语言。": "System menus such as Window switch language after restarting.",
  "立即重启": "Restart Now",
  "稍后": "Later",
  "确定": "OK",
  "应用": "Apply",
  "部分系统菜单项(如“窗口”)的语言需重启后切换。": "Some system menu items (such as Window) switch language after restarting.",
  "设置…": "Settings…",
  "设置": "Settings",
  "接口类型": "Provider",
  "OpenAI 兼容": "OpenAI-compatible",
  "接口地址": "Base URL",
  "模型名称": "Model",
  "API 密钥": "API Key",
  "API 密钥保存在系统钥匙串中,仅用于调用你配置的接口。": "The API key is stored in the macOS Keychain and only used to call the endpoint you configure.",
  "AI 协作": "AI Co-work",
  "发送": "Send",
  "发送中…": "Sending…",
  "新对话": "New Chat",
  "插入光标处": "Insert at Cursor",
  "附带当前文档": "Include Current Document",
  "清除": "Clear",
  "附件(%ld):%@": "Attachments (%ld): %@",
  "拖入文字、图片或文件到这里": "Drop text, images or files here",
  "无法读取该文件:%@": "Can't read file: %@",
  "我": "You",
  "请先在“设置”中填写 API 密钥": "Set your API key in Settings first.",
  "请求失败:%@": "Request failed: %@",
  "(空回复)": "(empty reply)",
  "你是嵌入在文本编辑器 Notapple 中的 AI 协作助手,回答简洁、可直接用于文档。": "You are an AI co-work assistant inside the text editor Notapple. Be concise; answers should be usable directly in documents.",
  "CR (旧 Mac)": "CR (classic Mac)",
  "图片  |  %ld × %ld 像素  |  %@": "Image  |  %ld × %ld px  |  %@",
  "切换阅读/编辑模式": "Toggle Reading / Editing Mode",
  "阅读模式(⌘. 返回编辑)": "Reading mode (⌘. to edit)",
  "PDF(只读预览)": "PDF (read-only preview)",
  "无法作为文本打开:%@": "Can't open as text: %@",
  "文件看起来是二进制。": "This file looks like binary data.",
  "文本": "Text",
  "纯文本": "Plain Text",
  "行 %ld, 列 %ld  |  %ld 字符  |  %@  |  %@": "Ln %ld, Col %ld  |  %ld chars  |  %@  |  %@",
  "无法用 %@ 表示当前文本中的部分字符": "Some characters can't be represented in %@",
  "当前编码无法表示文本中的部分字符,未写入文件": "The current encoding can't represent some characters. Nothing was written.",
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
  "退出 Notapple": "Quit Notapple",
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
  Lang("Python", "py pyw", "def class if elif else for while return import from as with try except finally raise lambda yield pass break continue in is not and or None True False global async await", lc: "#", bc: #"(?:"""[\s\S]*?"""|'''[\s\S]*?''')"#),
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
  Lang("LaTeX", "tex sty cls bib ltx", "", lc: "%", bc: nil, str: false,
       x: [(#"\\[A-Za-z@]+\*?|\\[^A-Za-z\s]"#, .systemPink), (#"\\(?:begin|end)\{[^}]*\}"#, .systemPurple),
           (#"\$\$[\s\S]*?\$\$|\$[^$\n]+\$"#, .systemOrange), (#"^@\w+(?=\{)"#, .systemPurple)]),
  Lang("Tcl/XDC", "tcl xdc sdc", "set proc if else foreach while return puts source create_clock set_property", lc: "#", bc: nil),
]
func detect(_ u: URL) -> Lang? { let e = u.pathExtension.lowercased(); return langs.first { $0.exts.contains(e) } }
func sniff(_ s: String) -> Lang? {   // 无扩展名/未保存文档:根据内容自动识别语法
  let h = String(s.prefix(6000)), t = h.trimmingCharacters(in: .whitespacesAndNewlines)
  if t.isEmpty { return nil }
  func L(_ n: String) -> Lang? { langs.first { $0.name == n } }
  func has(_ src: String, _ p: String) -> Bool { src.range(of: p, options: .regularExpression) != nil }
  if t.hasPrefix("#!") {
    let l = t.prefix { $0 != "\n" }.lowercased()
    for (k, n) in [("python", "Python"), ("ruby", "Ruby"), ("node", "JavaScript/TS"), ("php", "PHP"), ("lua", "Lua"), ("sh", "Shell")] where l.contains(k) { return L(n) }
  }
  if t.hasPrefix("<?php") { return L("PHP") }
  if t.hasPrefix("<?xml") || has(h, #"(?i)<!doctype html|<html[\s>]|<(div|body|head|svg|script)[\s>]"#) { return L("HTML/XML") }
  if t.hasPrefix("{") || t.hasPrefix("["), s.utf8.count < 500_000, (try? JSONSerialization.jsonObject(with: Data(s.utf8))) != nil { return L("JSON") }
  if has(h, #"\\documentclass|\\usepackage|\\begin\{(document|equation|align|itemize|figure|tabular)"#) { return L("LaTeX") }
  let heads = h.components(separatedBy: "\n").filter { has($0, #"^#{1,6} \S"#) }.count
  let other = [#"\]\("#, #"\*\*\S"#, #"(?m)^>\s"#, #"(?m)^\|.+\|\s*$"#, #"!\["#, #"(?m)^\s*[-*] \[[ x]\]"#].filter { has(h, $0) }.count
  if has(h, "```") && heads + other > 0 { return L("Markdown") }
  let code = h.replacingOccurrences(of: #"```[\s\S]*?(```|$)"#, with: "", options: .regularExpression)
  let rules: [(String, String)] = [
    ("Verilog/SV", #"(?m)^\s*module\s+\w+[\s\S]*?\b(wire|reg|logic|assign|always)\b"#),
    ("VHDL", #"(?i)\b(entity\s+\w+\s+is|architecture\s+\w+\s+of|std_logic)\b"#),
    ("SQL", #"(?im)^\s*(select\s[\s\S]+?\sfrom\s|insert\s+into\s|create\s+table\s|alter\s+table\s|delete\s+from\s)"#),
    ("Go", #"(?m)^package\s+\w+\s*$[\s\S]*?\b(func|import)\b"#),
    ("Rust", #"\bfn\s+\w+\s*[(<]|\blet\s+mut\b|\buse\s+std::"#),
    ("Swift", #"(?m)^\s*(import\s+(Foundation|SwiftUI|UIKit|Cocoa|AppKit)\b|(public\s+|private\s+|final\s+)*(struct|class|enum|protocol|extension)\s+\w+|func\s+\w+\s*\(.*\)\s*(->|\{))"#),
    ("Python", #"(?m)^\s*(def\s+\w+\s*\(.*\)\s*(->.*)?:|class\s+\w+(\(.*\))?\s*:|from\s+[\w.]+\s+import\s|import\s+\w+(\s+as\s+\w+)?\s*$|if\s+__name__)"#),
    ("Java/Kotlin/C#", #"\b(public|private|protected)\s+(static\s+)?(final\s+)?(class|void|int|String|string)\b|using\s+System;|System\.out\.print|(?m)^\s*package\s+[\w.]+;"#),
    ("C/C++/ObjC", #"(?m)^\s*#\s*include\s*[<"]|\bint\s+main\s*\(|std::"#),
    ("JavaScript/TS", #"\b(const|let|var)\s+\w+\s*=|\bfunction\s*\w*\s*\(|=>\s*[{(\w]|console\.log|\brequire\(|(?m)^\s*import\s.+\sfrom\s|export\s+(default|const|function)"#),
    ("CSS", #"(?m)^[.#@\w][^{}\n]*\{\s*\n?\s*[\w-]+\s*:\s*[^;{}]+;"#),
  ]
  for (n, p) in rules where has(code, p) { return L(n) }
  if (heads >= 1 && has(h, #"(?m)^#{1,6} \S.*\n\s*\n"#)) || (heads >= 1 && other >= 1) || other >= 2 { return L("Markdown") }
  let lines = h.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
  let kv = lines.filter { has($0, #"^\s*[\w.-]+:(\s+\S.*)?$|^\s*- \S"#) }.count
  if lines.count >= 3 && kv * 10 >= lines.count * 7 && has(h, #"(?m)^[\w.-]+:"#) { return L("YAML/INI/TOML") }
  return nil
}


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

// MARK: Markdown → HTML(自带转换器,无第三方依赖;Markdown 中的原始 HTML 一律转义)
func esc(_ s: String) -> String {
  s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
   .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
}
func rx(_ s: String, _ p: String, _ t: String) -> String { s.replacingOccurrences(of: p, with: t, options: .regularExpression) }
// MARK: LaTeX 公式 → MathML(WebKit 原生渲染:无需 JS、无需外部库、可离线)
let texGreek: [String: String] = ["alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ", "epsilon": "ϵ", "varepsilon": "ε", "zeta": "ζ", "eta": "η", "theta": "θ", "vartheta": "ϑ", "iota": "ι", "kappa": "κ", "lambda": "λ", "mu": "μ", "nu": "ν", "xi": "ξ", "pi": "π", "varpi": "ϖ", "rho": "ρ", "varrho": "ϱ", "sigma": "σ", "varsigma": "ς", "tau": "τ", "upsilon": "υ", "phi": "ϕ", "varphi": "φ", "chi": "χ", "psi": "ψ", "omega": "ω", "Gamma": "Γ", "Delta": "Δ", "Theta": "Θ", "Lambda": "Λ", "Xi": "Ξ", "Pi": "Π", "Sigma": "Σ", "Upsilon": "Υ", "Phi": "Φ", "Psi": "Ψ", "Omega": "Ω"]
let texOp: [String: String] = ["times": "×", "cdot": "⋅", "pm": "±", "mp": "∓", "div": "÷", "ast": "∗", "star": "⋆", "circ": "∘", "bullet": "∙", "leq": "≤", "le": "≤", "geq": "≥", "ge": "≥", "neq": "≠", "ne": "≠", "approx": "≈", "sim": "∼", "simeq": "≃", "cong": "≅", "equiv": "≡", "propto": "∝", "ll": "≪", "gg": "≫", "infty": "∞", "partial": "∂", "nabla": "∇", "to": "→", "rightarrow": "→", "leftarrow": "←", "gets": "←", "leftrightarrow": "↔", "Rightarrow": "⇒", "Leftarrow": "⇐", "Leftrightarrow": "⇔", "iff": "⟺", "implies": "⟹", "mapsto": "↦", "uparrow": "↑", "downarrow": "↓", "in": "∈", "notin": "∉", "ni": "∋", "subset": "⊂", "supset": "⊃", "subseteq": "⊆", "supseteq": "⊇", "cup": "∪", "cap": "∩", "setminus": "∖", "emptyset": "∅", "varnothing": "∅", "forall": "∀", "exists": "∃", "neg": "¬", "lnot": "¬", "land": "∧", "wedge": "∧", "lor": "∨", "vee": "∨", "oplus": "⊕", "otimes": "⊗", "odot": "⊙", "perp": "⊥", "parallel": "∥", "mid": "∣", "angle": "∠", "ldots": "…", "dots": "…", "cdots": "⋯", "vdots": "⋮", "ddots": "⋱", "hbar": "ℏ", "ell": "ℓ", "Re": "ℜ", "Im": "ℑ", "aleph": "ℵ", "prime": "′", "degree": "°", "sum": "∑", "prod": "∏", "coprod": "∐", "int": "∫", "iint": "∬", "iiint": "∭", "oint": "∮", "bigcup": "⋃", "bigcap": "⋂", "bigoplus": "⨁", "bigotimes": "⨂", "langle": "⟨", "rangle": "⟩", "lfloor": "⌊", "rfloor": "⌋", "lceil": "⌈", "rceil": "⌉", "lbrace": "{", "rbrace": "}", "vert": "|", "Vert": "‖", "triangle": "△", "square": "□", "therefore": "∴", "because": "∵", "dagger": "†", "sqcup": "⊔"]
let texFn: Set<String> = ["sin", "cos", "tan", "cot", "sec", "csc", "log", "ln", "exp", "lim", "max", "min", "sup", "inf", "det", "gcd", "arg", "dim", "ker", "deg", "limsup", "liminf", "sinh", "cosh", "tanh", "arcsin", "arccos", "arctan", "Pr"]
let limOps: Set<String> = ["sum", "prod", "coprod", "bigcup", "bigcap", "bigoplus", "bigotimes", "lim", "max", "min", "sup", "inf", "limsup", "liminf"]
let texAccent: [String: String] = ["hat": "^", "widehat": "^", "bar": "¯", "overline": "¯", "vec": "→", "tilde": "~", "widetilde": "~", "dot": "˙", "ddot": "¨"]
let texSkip: Set<String> = ["displaystyle", "textstyle", "scriptstyle", "limits", "nolimits", "big", "Big", "bigg", "Bigg", "bigl", "bigr", "Bigl", "Bigr", "biggl", "biggr", "nonumber", "notag"]
let bbMap: [Character: String] = ["R": "ℝ", "N": "ℕ", "Z": "ℤ", "Q": "ℚ", "C": "ℂ", "H": "ℍ", "P": "ℙ"]
func mo(_ s: String) -> String { s.isEmpty ? "" : "<mo fence=\"true\" stretchy=\"true\">" + esc(s) + "</mo>" }
final class TeX {
  let c: [Character]; var i = 0
  init(_ s: String) { c = Array(s) }
  var cur: Character? { i < c.count ? c[i] : nil }
  func ws() { while let ch = cur, ch.isWhitespace { i += 1 } }
  func peek(_ s: String) -> Bool { let a = Array(s); return i + a.count <= c.count && Array(c[i..<(i + a.count)]) == a }
  func peekCmd(_ n: String) -> Bool { let e = i + n.count + 1; return peek("\\" + n) && !(e < c.count && c[e].isASCII && c[e].isLetter) }
  func name() -> String {
    guard let ch = cur else { return "" }
    if ch.isASCII && ch.isLetter { var n = ""; while let x = cur, x.isASCII && x.isLetter { n.append(x); i += 1 }; return n }
    i += 1; return String(ch)
  }
  func raw() -> String {
    ws(); var t = ""; guard cur == "{" else { return t }; i += 1; var d = 1
    while let x = cur { i += 1; if x == "{" { d += 1 } else if x == "}" { d -= 1; if d == 0 { break } }; t.append(x) }
    return t
  }
  func atEnd() -> Bool { ws(); guard let ch = cur else { return true }; return ch == "}" || ch == "&" || peek("\\\\") || peekCmd("right") || peekCmd("end") }
  func row() -> String { var o = ""; while !atEnd() { o += atom() }; return o }
  func arg() -> String {
    ws(); if cur == nil || cur == "}" || cur == "&" { return "<mrow></mrow>" }
    if cur == "{" { i += 1; let r = row(); if cur == "}" { i += 1 }; return "<mrow>" + r + "</mrow>" }
    return primary().0
  }
  func atom() -> String {
    let (b, lim) = primary(); var sub = "", sup = ""
    while true {
      ws()
      if cur == "^" { i += 1; sup += arg() } else if cur == "_" { i += 1; sub += arg() } else if cur == "'" { i += 1; sup += "<mo>′</mo>" } else { break }
    }
    if sub.isEmpty && sup.isEmpty { return b }
    if lim { return sup.isEmpty ? "<munder>\(b)<mrow>\(sub)</mrow></munder>" : (sub.isEmpty ? "<mover>\(b)<mrow>\(sup)</mrow></mover>" : "<munderover>\(b)<mrow>\(sub)</mrow><mrow>\(sup)</mrow></munderover>") }
    return sup.isEmpty ? "<msub>\(b)<mrow>\(sub)</mrow></msub>" : (sub.isEmpty ? "<msup>\(b)<mrow>\(sup)</mrow></msup>" : "<msubsup>\(b)<mrow>\(sub)</mrow><mrow>\(sup)</mrow></msubsup>")
  }
  func primary() -> (String, Bool) {
    ws(); guard let ch = cur else { return ("", false) }
    if ch == "{" { i += 1; let r = row(); if cur == "}" { i += 1 }; return ("<mrow>" + r + "</mrow>", false) }
    if ch.isASCII && ch.isNumber {
      var n = ""; while let x = cur, (x.isASCII && x.isNumber) || (x == "." && i + 1 < c.count && c[i + 1].isNumber) { n.append(x); i += 1 }
      return ("<mn>" + n + "</mn>", false)
    }
    if ch.isLetter { i += 1; return ("<mi>" + String(ch) + "</mi>", false) }
    i += 1
    if ch == "\\" { return command() }
    switch ch {
    case "-": return ("<mo>−</mo>", false)
    case "<": return ("<mo>&lt;</mo>", false)
    case ">": return ("<mo>&gt;</mo>", false)
    case "&": return ("<mo>&amp;</mo>", false)
    case "~": return ("<mspace width=\"0.3em\"/>", false)
    default: return ("<mo>" + String(ch) + "</mo>", false)
    }
  }
  func delim() -> String {
    ws(); guard let ch = cur else { return "" }; i += 1
    if ch == "." { return "" }
    if ch == "\\" { let n = name(); if n == "|" { return "‖" }; if n == "{" || n == "}" { return n }; return texOp[n] ?? "" }
    return String(ch)
  }
  func command() -> (String, Bool) {
    let n = name()
    switch n {
    case "frac", "dfrac", "tfrac": let a = arg(), b = arg(); return ("<mfrac>" + a + b + "</mfrac>", false)
    case "binom": let a = arg(), b = arg(); return ("<mrow><mo>(</mo><mfrac linethickness=\"0\">" + a + b + "</mfrac><mo>)</mo></mrow>", false)
    case "sqrt":
      ws()
      if cur == "[" { i += 1; var d = ""; while let x = cur, x != "]" { d.append(x); i += 1 }; i += 1; let a = arg(); return ("<mroot>" + a + "<mrow>" + TeX(d).row() + "</mrow></mroot>", false) }
      return ("<msqrt>" + arg() + "</msqrt>", false)
    case "text", "textrm", "mbox": return ("<mtext>" + esc(raw()) + "</mtext>", false)
    case "mathrm", "operatorname": return ("<mi mathvariant=\"normal\">" + esc(raw()) + "</mi>", false)
    case "mathbf", "textbf", "boldsymbol", "bm": return ("<mrow style=\"font-weight:bold\">" + arg() + "</mrow>", false)
    case "mathit": return ("<mi>" + esc(raw()) + "</mi>", false)
    case "mathbb": return ("<mi>" + raw().map { bbMap[$0] ?? String($0) }.joined() + "</mi>", false)
    case "mathcal", "mathscr", "mathfrak": return ("<mrow>" + arg() + "</mrow>", false)
    case "left":
      let o = delim(), r = row(); var cl = ""; if peekCmd("right") { i += 6; cl = delim() }
      return ("<mrow>" + mo(o) + r + mo(cl) + "</mrow>", false)
    case "right": _ = delim(); return ("", false)
    case "underline": return ("<munder>" + arg() + "<mo>_</mo></munder>", false)
    case "begin":
      guard cur == "{" else { return ("", false) }
      i += 1; var e = ""; while let x = cur, x != "}" { e.append(x); i += 1 }; i += 1
      if e == "array" { _ = raw() }
      var rows: [[String]] = [[]], cell = ""
      while true {
        cell += row(); ws()
        if cur == "&" { i += 1; rows[rows.count - 1].append(cell); cell = "" }
        else if peek("\\\\") { i += 2; rows[rows.count - 1].append(cell); cell = ""; rows.append([]) }
        else { break }
      }
      rows[rows.count - 1].append(cell)
      if rows.count > 1, rows[rows.count - 1] == [""] { rows.removeLast() }
      if peekCmd("end") { i += 4; _ = raw() }
      var tbl = "<mtable" + (["align", "aligned", "split", "align*"].contains(e) ? " columnalign=\"right left\"" : (e == "cases" ? " columnalign=\"left left\"" : "")) + ">"
      for r in rows { tbl += "<mtr>" + r.map { "<mtd>" + $0 + "</mtd>" }.joined() + "</mtr>" }
      tbl += "</mtable>"
      let (l, r): (String, String) = ["pmatrix": ("(", ")"), "bmatrix": ("[", "]"), "Bmatrix": ("{", "}"), "vmatrix": ("|", "|"), "Vmatrix": ("‖", "‖"), "cases": ("{", "")][e] ?? ("", "")
      return ("<mrow>" + mo(l) + tbl + mo(r) + "</mrow>", false)
    case ",": return ("<mspace width=\"0.17em\"/>", false)
    case ":", ";", " ": return ("<mspace width=\"0.25em\"/>", false)
    case "quad": return ("<mspace width=\"1em\"/>", false)
    case "qquad": return ("<mspace width=\"2em\"/>", false)
    case "!", "": return ("", false)
    case "{", "}", "%", "$", "#", "_": return ("<mo>" + n + "</mo>", false)
    case "&": return ("<mo>&amp;</mo>", false)
    case "|": return ("<mo>‖</mo>", false)
    default:
      if texSkip.contains(n) { return ("", false) }
      if let a = texAccent[n] { return ("<mover accent=\"true\">" + arg() + "<mo>" + a + "</mo></mover>", false) }
      if let g = texGreek[n] { return ("<mi>" + g + "</mi>", false) }
      if let o = texOp[n] { return ("<mo>" + o + "</mo>", limOps.contains(n)) }
      if texFn.contains(n) { return ("<mi>" + n + "</mi>", limOps.contains(n)) }
      return ("<mtext>\\" + esc(n) + "</mtext>", false)   // 未支持的命令:原样显示
    }
  }
}
func texToMathML(_ tex: String, block: Bool) -> String {
  let t = TeX(tex.trimmingCharacters(in: .whitespacesAndNewlines)); var out = ""
  while t.i < t.c.count { out += t.row(); if t.i < t.c.count { t.i += t.peek("\\\\") ? 2 : 1 } }
  return "<math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"" + (block ? "block" : "inline") + "\">" + out + "</math>"
}
func stashAll(_ s: String, _ pat: String, _ stash: inout [String], _ f: (NSTextCheckingResult, NSString) -> String) -> String {
  let ns = s as NSString, re = try! NSRegularExpression(pattern: pat)
  var out = "", last = 0
  for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
    out += ns.substring(with: NSRange(location: last, length: m.range.location - last))
    stash.append(f(m, ns)); out += "\u{1}\(stash.count - 1)\u{1}"; last = NSMaxRange(m.range)
  }
  return out + ns.substring(from: last)
}
func inline(_ t: String) -> String {
  var stash: [String] = []
  var out = stashAll(t, "`([^`]+)`", &stash) { m, ns in "<code>" + esc(ns.substring(with: m.range(at: 1))) + "</code>" }
  out = stashAll(out, #"(?<!\\)\$(?=[^\s$])([^$\n]*?[^\s$\\])\$(?!\d)"#, &stash) { m, ns in texToMathML(ns.substring(with: m.range(at: 1)), block: false) }
  out = esc(out)
  out = rx(out, #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+&quot;.*?&quot;)?\)"#, #"<img alt="$1" src="$2">"#)
  out = rx(out, #"\[([^\]]+)\]\(([^)\s]+)(?:\s+&quot;.*?&quot;)?\)"#, #"<a href="$2">$1</a>"#)
  out = rx(out, #"\*\*(.+?)\*\*|__(.+?)__"#, "<strong>$1$2</strong>")
  out = rx(out, #"\*([^*\s][^*]*?)\*|\b_([^_]+)_\b"#, "<em>$1$2</em>")
  out = rx(out, #"~~(.+?)~~"#, "<del>$1</del>")
  for (k, c) in stash.enumerated() { out = out.replacingOccurrences(of: "\u{1}\(k)\u{1}", with: c) }
  return out
}
func cells(_ l: String) -> [String] {
  var p = l.trimmingCharacters(in: .whitespaces); if p.hasPrefix("|") { p.removeFirst() }; if p.hasSuffix("|") { p.removeLast() }
  return p.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
}
let listRE = try! NSRegularExpression(pattern: #"^([ \t]*)([-*+]|\d+[.)])[ \t]+(.*)$"#)
func mdHTML(_ src: String) -> String {
  let L = src.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n").components(separatedBy: "\n")
  var o = "", i = 0, para: [String] = [], lists: [(String, Int)] = []
  func flush() { if !para.isEmpty { o += "<p>" + rx(inline(para.joined(separator: "\n")), "  \n", "<br>\n") + "</p>\n"; para = [] } }
  func closeLists() { while !lists.isEmpty { o += "</li></" + lists.removeLast().0 + ">\n" } }
  while i < L.count {
    let l = L[i], t = l.trimmingCharacters(in: .whitespaces)
    if t.hasPrefix("```") || t.hasPrefix("~~~") {
      flush(); closeLists(); let f = String(t.prefix(3)); var code: [String] = []; i += 1
      while i < L.count, !L[i].trimmingCharacters(in: .whitespaces).hasPrefix(f) { code.append(L[i]); i += 1 }
      o += "<pre><code>" + esc(code.joined(separator: "\n")) + "</code></pre>\n"; i += 1; continue
    }
    if t.isEmpty { flush(); i += 1; continue }
    if t.hasPrefix("$$") {
      flush(); closeLists(); var body = String(t.dropFirst(2)); i += 1
      if let r = body.range(of: "$$") { body = String(body[..<r.lowerBound]) }
      else { while i < L.count { let u = L[i]; i += 1; if let r = u.range(of: "$$") { body += "\n" + String(u[..<r.lowerBound]); break }; body += "\n" + u } }
      o += "<div class=math>" + texToMathML(body, block: true) + "</div>\n"; continue
    }
    if t.range(of: #"^#{1,6}\s"#, options: .regularExpression) != nil {
      flush(); closeLists(); let n = t.prefix { $0 == "#" }.count
      o += "<h\(n)>" + inline(rx(String(t.dropFirst(n)).trimmingCharacters(in: .whitespaces), #"\s+#+$"#, "")) + "</h\(n)>\n"; i += 1; continue
    }
    if t.range(of: #"^([-*_])([ ]*\1){2,}$"#, options: .regularExpression) != nil { flush(); closeLists(); o += "<hr>\n"; i += 1; continue }
    if t.contains("|"), i + 1 < L.count, L[i + 1].range(of: #"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$"#, options: .regularExpression) != nil {
      flush(); closeLists()
      let al = cells(L[i + 1]).map { c -> String in c.hasPrefix(":") && c.hasSuffix(":") ? "center" : (c.hasSuffix(":") ? "right" : (c.hasPrefix(":") ? "left" : "")) }
      func row(_ c: [String], _ tag: String) -> String {
        var r = "<tr>"
        for (k, v) in c.enumerated() {
          let a = k < al.count ? al[k] : "", st = a.isEmpty ? "" : " style='text-align:" + a + "'"
          r += "<" + tag + st + ">" + inline(v) + "</" + tag + ">"
        }
        return r + "</tr>\n"
      }
      o += "<table>\n" + row(cells(t), "th"); i += 2
      while i < L.count, L[i].contains("|"), !L[i].trimmingCharacters(in: .whitespaces).isEmpty { o += row(cells(L[i]), "td"); i += 1 }
      o += "</table>\n"; continue
    }
    if t.hasPrefix(">") {
      flush(); closeLists(); var q: [String] = []
      while i < L.count, L[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") { q.append(rx(L[i].trimmingCharacters(in: .whitespaces), #"^>\s?"#, "")); i += 1 }
      o += "<blockquote>" + mdHTML(q.joined(separator: "\n")) + "</blockquote>\n"; continue
    }
    let ns = l as NSString
    if let m = listRE.firstMatch(in: l, range: NSRange(location: 0, length: ns.length)) {
      flush()
      let ind = ns.substring(with: m.range(at: 1)).reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
      let tag = ns.substring(with: m.range(at: 2)).first!.isNumber ? "ol" : "ul"
      var tx = ns.substring(with: m.range(at: 3)), box = ""
      if tx.hasPrefix("[ ] ") { box = "<input type=checkbox disabled> "; tx.removeFirst(4) }
      else if tx.lowercased().hasPrefix("[x] ") { box = "<input type=checkbox checked disabled> "; tx.removeFirst(4) }
      if lists.isEmpty || ind > lists.last!.1 + 1 { o += "<" + tag + ">\n"; lists.append((tag, ind)) }
      else { while lists.count > 1 && ind < lists.last!.1 { o += "</li></" + lists.removeLast().0 + ">\n" }; o += "</li>\n" }
      o += "<li>" + box + inline(tx); i += 1; continue
    }
    if !lists.isEmpty && (l.hasPrefix(" ") || l.hasPrefix("\t")) { o += " " + inline(t); i += 1; continue }
    closeLists(); para.append(String(l.drop { $0 == " " || $0 == "\t" })); i += 1
  }
  flush(); closeLists(); return o
}
let mdCSS = #"""
body{font:16px/1.7 -apple-system,"PingFang SC",sans-serif;max-width:780px;margin:0 auto;padding:32px 28px 80px}
h1,h2,h3,h4,h5,h6{margin:1.4em 0 .6em;line-height:1.3}h1,h2{border-bottom:1px solid #8884;padding-bottom:.3em}
code{font:13px ui-monospace,Menlo,monospace;background:#8882;padding:.15em .4em;border-radius:4px}
pre{background:#8881;border:1px solid #8883;padding:14px;border-radius:8px;overflow:auto}pre code{background:none;padding:0}
blockquote{margin:1em 0;padding:.2em 1em;border-left:4px solid #1a8c7a;color:#8a8a8a}
table{border-collapse:collapse}td,th{border:1px solid #8886;padding:6px 12px}th{background:#8882}
math{font-size:1.15em}.math{overflow-x:auto;text-align:center;margin:.8em 0}img{max-width:100%}hr{border:0;border-top:1px solid #8884}a{color:#1a8c7a}
"""#
func mdPage(_ src: String, _ base: URL?) -> String {
  let b = base.map { "<base href=\"" + esc($0.deletingLastPathComponent().absoluteString) + "\">" } ?? ""
  return "<!doctype html><meta charset=utf-8><meta name=color-scheme content=\"light dark\">" + b + "<style>" + mdCSS + "</style>" + mdHTML(src)
}

// MARK: 编辑区:拦截文件拖放;Markdown 下拖入图片 = 在光标处插入 ![](路径)
let imgExts: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tif", "tiff", "webp", "heic", "heif", "ico", "svg"]
func relPath(_ target: URL, from dir: URL) -> String {
  let t = target.standardizedFileURL.pathComponents, d = dir.standardizedFileURL.pathComponents
  var k = 0; while k < t.count, k < d.count, t[k] == d[k] { k += 1 }
  return (Array(repeating: "..", count: d.count - k) + t[k...]).joined(separator: "/")
}
final class EditView: NSTextView {
  weak var doc: Doc?
  override init(frame: NSRect, textContainer: NSTextContainer?) { super.init(frame: frame, textContainer: textContainer); registerForDraggedTypes([.fileURL]) }
  override init(frame: NSRect) { super.init(frame: frame); registerForDraggedTypes([.fileURL]) }
  required init?(coder: NSCoder) { fatalError() }
  override func updateDragTypeRegistration() { super.updateDragTypeRegistration(); registerForDraggedTypes([.fileURL]) }
  func files(_ s: NSDraggingInfo) -> [URL] {
    (s.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
  }
  func index(_ s: NSDraggingInfo) -> Int { characterIndexForInsertion(at: convert(s.draggingLocation, from: nil)) }
  override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation {
    if files(s).isEmpty { return super.draggingEntered(s) }
    window?.makeFirstResponder(self); return .copy
  }
  override func draggingUpdated(_ s: NSDraggingInfo) -> NSDragOperation {
    if files(s).isEmpty { return super.draggingUpdated(s) }
    let i = index(s); setSelectedRange(NSRange(location: i, length: 0)); scrollRangeToVisible(NSRange(location: i, length: 0))   // 光标跟随鼠标 = 插入位置
    return .copy
  }
  override func prepareForDragOperation(_ s: NSDraggingInfo) -> Bool { files(s).isEmpty ? super.prepareForDragOperation(s) : true }
  override func performDragOperation(_ s: NSDraggingInfo) -> Bool {
    let f = files(s); if f.isEmpty { return super.performDragOperation(s) }
    doc?.dropFiles(f, at: index(s)); return true
  }
}
func makeScroll(_ t: NSTextView = EditView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))) -> NSScrollView {
  let sv = NSScrollView(); sv.hasVerticalScroller = true; sv.borderType = .noBorder
  t.minSize = NSSize(width: 0, height: 0); t.maxSize = NSSize(width: 1e7, height: 1e7)
  t.isVerticallyResizable = true; t.isHorizontallyResizable = false; t.autoresizingMask = [.width]
  t.textContainer?.containerSize = NSSize(width: 600, height: 1e7); t.textContainer?.widthTracksTextView = true
  sv.documentView = t; return sv
}

// MARK: AI 协作(右侧栏聊天):模型接口 / 附件 / 拖放
struct Attach { var name: String; var text: String?; var img: Data?; var mime: String }
struct Msg { var role: String; var text: String; var files: [Attach] }
enum Keychain {   // API 密钥存系统钥匙串
  static let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "notapple.ai", kSecAttrAccount as String: "apikey"]
  static func get() -> String? {
    var r = q; r[kSecReturnData as String] = true; var out: AnyObject?
    guard SecItemCopyMatching(r as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
    return String(data: d, encoding: .utf8)
  }
  static func set(_ v: String) {
    SecItemDelete(q as CFDictionary); guard !v.isEmpty else { return }
    var a = q; a[kSecValueData as String] = Data(v.utf8); SecItemAdd(a as CFDictionary, nil)
  }
}
enum AI {
  static let defs: [(String, String)] = [("https://api.anthropic.com", "claude-sonnet-5-5"), ("https://api.openai.com", "gpt-4o")]
  static func endpoint(_ base: String, _ path: String) -> String {
    let b = base.trimmingCharacters(in: CharacterSet(charactersIn: "/ \n")); return b.hasSuffix("/v1") ? b + path : b + "/v1" + path
  }
  static func ask(_ msgs: [Msg], system: String, done: @escaping (Bool, String) -> Void) {
    let d = UserDefaults.standard, prov = d.integer(forKey: "ai.provider")
    let base = d.string(forKey: "ai.base").flatMap { $0.isEmpty ? nil : $0 } ?? defs[prov].0
    let model = d.string(forKey: "ai.model").flatMap { $0.isEmpty ? nil : $0 } ?? defs[prov].1
    guard let key = Keychain.get(), !key.isEmpty else { done(false, T("请先在“设置”中填写 API 密钥")); return }
    guard let url = URL(string: endpoint(base, prov == 0 ? "/messages" : "/chat/completions")) else { done(false, String(format: T("请求失败:%@"), base)); return }
    func blocks(_ m: Msg) -> Any {
      if m.role != "user" { return m.text }
      var b: [[String: Any]] = []
      for f in m.files {
        if let im = f.img {
          let b64 = im.base64EncodedString()
          let blk: [String: Any] = prov == 0 ? ["type": "image", "source": ["type": "base64", "media_type": f.mime, "data": b64]] : ["type": "image_url", "image_url": ["url": "data:" + f.mime + ";base64," + b64]]
          b.append(blk)
        } else if let t = f.text { b.append(["type": "text", "text": "[" + f.name + "]\n" + t]) }
      }
      if !m.text.isEmpty { b.append(["type": "text", "text": m.text]) }
      return b
    }
    let ms: [[String: Any]] = msgs.map { ["role": $0.role, "content": blocks($0)] }
    var req = URLRequest(url: url); var body: [String: Any]
    if prov == 0 {
      req.setValue(key, forHTTPHeaderField: "x-api-key"); req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
      body = ["model": model, "max_tokens": 4096, "system": system, "messages": ms]
    } else {
      req.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
      let sysMsg: [String: Any] = ["role": "system", "content": system]
      body = ["model": model, "messages": [sysMsg] + ms]
    }
    req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "content-type"); req.timeoutInterval = 180
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
    URLSession.shared.dataTask(with: req) { data, resp, err in
      var ok = false, out = ""
      if let err = err { out = String(format: T("请求失败:%@"), err.localizedDescription) }
      else if let data = data, let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        if let e = j["error"] as? [String: Any] { out = String(format: T("请求失败:%@"), (e["message"] as? String) ?? "error") }
        else if prov == 0 { out = ((j["content"] as? [[String: Any]]) ?? []).compactMap { $0["text"] as? String }.joined(); ok = true }
        else { out = (((j["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String) ?? ""; ok = true }
      } else { out = String(format: T("请求失败:%@"), "HTTP \((resp as? HTTPURLResponse)?.statusCode ?? 0)") }
      DispatchQueue.main.async { done(ok, out.isEmpty && ok ? T("(空回复)") : out) }
    }.resume()
  }
}
func pngData(_ i: NSImage?) -> Data? {
  guard let t = i?.tiffRepresentation, let r = NSBitmapImageRep(data: t) else { return nil }
  return r.representation(using: .png, properties: [:])
}
func loadAttach(_ u: URL) -> Attach? {   // 文件 / 图片 / PDF / 文件夹 → 可发给模型的附件
  let e = u.pathExtension.lowercased(), n = u.lastPathComponent
  var isDir: ObjCBool = false; FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir)
  if isDir.boolValue {
    var names: [String] = []
    if let en = FileManager.default.enumerator(at: u, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
      for case let x as URL in en { names.append(x.path.replacingOccurrences(of: u.path + "/", with: "")); if names.count >= 300 { break } }
    }
    return Attach(name: n + "/", text: names.joined(separator: "\n"), img: nil, mime: "")
  }
  if imgExts.contains(e) && e != "svg" {
    guard let d = try? Data(contentsOf: u), d.count < 20_000_000 else { return nil }
    let direct = ["png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif", "webp": "image/webp"]
    if let m = direct[e], d.count < 5_000_000 { return Attach(name: n, text: nil, img: d, mime: m) }
    if let png = pngData(NSImage(data: d)) { return Attach(name: n, text: nil, img: png, mime: "image/png") }
    return nil
  }
  if e == "pdf" { guard let t = PDFDocument(url: u)?.string else { return nil }; return Attach(name: n, text: String(t.prefix(150_000)), img: nil, mime: "") }
  guard let d = try? Data(contentsOf: u), let (s, _, _) = decode(d) else { return nil }
  return Attach(name: n, text: String(s.prefix(150_000)), img: nil, mime: "")
}

// 圆形 AI 按钮 · 原创标识「观」:杏仁形的眼 = 洞察与智慧;瞳孔处的四角星 = 一闪而过的灵感;
// 倾斜的轨道环与光点 = 科幻 / 计算。眼宽取黄金分割 0.618,色彩只留一处暖色(星),其余是深海蓝与白。
final class RoundButton: NSButton {
  override func draw(_ dirtyRect: NSRect) {
    let b = bounds.insetBy(dx: 1.5, dy: 1.5), m = NSPoint(x: bounds.midX, y: bounds.midY), r = b.width / 2, w = NSColor.white
    NSGradient(starting: NSColor(calibratedRed: 0.09, green: 0.24, blue: 0.34, alpha: 1), ending: NSColor(calibratedRed: 0.02, green: 0.07, blue: 0.13, alpha: 1))!
      .draw(in: NSBezierPath(ovalIn: b), angle: -90)
    let rim = NSBezierPath(ovalIn: b.insetBy(dx: 0.5, dy: 0.5)); rim.lineWidth = 1; w.withAlphaComponent(0.16).setStroke(); rim.stroke()
    var tf = AffineTransform(translationByX: m.x, byY: m.y); tf.rotate(byDegrees: -24)
    let orbit = NSBezierPath(ovalIn: NSRect(x: -r * 0.82, y: -r * 0.27, width: r * 1.64, height: r * 0.54)); orbit.transform(using: tf)
    orbit.lineWidth = 0.9; w.withAlphaComponent(0.38).setStroke(); orbit.stroke()
    let a = r * 0.618, h = r * 0.25, eye = NSBezierPath()
    eye.move(to: NSPoint(x: m.x - a, y: m.y))
    eye.curve(to: NSPoint(x: m.x + a, y: m.y), controlPoint1: NSPoint(x: m.x - a * 0.45, y: m.y + h * 1.9), controlPoint2: NSPoint(x: m.x + a * 0.45, y: m.y + h * 1.9))
    eye.curve(to: NSPoint(x: m.x - a, y: m.y), controlPoint1: NSPoint(x: m.x + a * 0.45, y: m.y - h * 1.9), controlPoint2: NSPoint(x: m.x - a * 0.45, y: m.y - h * 1.9))
    eye.lineWidth = 1.5; eye.lineJoinStyle = .round; w.withAlphaComponent(0.94).setStroke(); eye.stroke()
    let k = r * 0.13, star = NSBezierPath()
    let pts: [(CGFloat, CGFloat)] = [(0, 2), (0.42, 0.42), (2, 0), (0.42, -0.42), (0, -2), (-0.42, -0.42), (-2, 0), (-0.42, 0.42)]
    star.move(to: NSPoint(x: m.x + pts[0].0 * k, y: m.y + pts[0].1 * k))
    for q in pts.dropFirst() { star.line(to: NSPoint(x: m.x + q.0 * k, y: m.y + q.1 * k)) }
    star.close(); NSColor(calibratedRed: 0.98, green: 0.74, blue: 0.28, alpha: 1).setFill(); star.fill()
    let t: CGFloat = 0.55, d = tf.transform(NSPoint(x: r * 0.82 * cos(t), y: r * 0.27 * sin(t)))
    w.setFill(); NSBezierPath(ovalIn: NSRect(x: d.x - 1.7, y: d.y - 1.7, width: 3.4, height: 3.4)).fill()
  }
}
// 图片标签页:可把图片拖出(拖进聊天框即作为附件)
final class DragImageView: NSImageView, NSDraggingSource {
  var fileURL: URL?
  func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { .copy }
  override func mouseDragged(with e: NSEvent) {
    guard let u = fileURL else { return }
    let it = NSDraggingItem(pasteboardWriter: u as NSURL); it.setDraggingFrame(bounds, contents: image)
    beginDraggingSession(with: [it], event: e, source: self)
  }
}
final class ChatInput: NSTextView {
  weak var pane: ChatPane?
  override init(frame: NSRect, textContainer: NSTextContainer?) { super.init(frame: frame, textContainer: textContainer); registerForDraggedTypes([.fileURL, .png, .tiff]) }
  override init(frame: NSRect) { super.init(frame: frame); registerForDraggedTypes([.fileURL, .png, .tiff]) }
  required init?(coder: NSCoder) { fatalError() }
  override func updateDragTypeRegistration() { super.updateDragTypeRegistration(); registerForDraggedTypes([.fileURL, .png, .tiff]) }
  func media(_ pb: NSPasteboard) -> Bool {
    pb.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) || pb.canReadObject(forClasses: [NSImage.self], options: nil)
  }
  override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation { media(s.draggingPasteboard) ? .copy : super.draggingEntered(s) }
  override func draggingUpdated(_ s: NSDraggingInfo) -> NSDragOperation { media(s.draggingPasteboard) ? .copy : super.draggingUpdated(s) }
  override func performDragOperation(_ s: NSDraggingInfo) -> Bool { media(s.draggingPasteboard) ? (pane?.ingest(s.draggingPasteboard) ?? false) : super.performDragOperation(s) }
  override func paste(_ sender: Any?) { if media(.general) { _ = pane?.ingest(.general) } else { super.paste(sender) } }
}
final class ChatPane: NSView, NSTextViewDelegate {
  weak var doc: Doc?
  let transcript = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 400)), input = ChatInput(frame: NSRect(x: 0, y: 0, width: 300, height: 70))
  var logScroll: NSScrollView!, inScroll: NSScrollView!
  let attLabel = NSTextField(labelWithString: ""), clearBtn = NSButton(), sendBtn = NSButton(), newBtn = NSButton()
  var hist: [Msg] = [], atts: [Attach] = [], busy = false, last = ""

  init(_ d: Doc) {
    doc = d; super.init(frame: .zero)
    registerForDraggedTypes([.fileURL, .png, .tiff, .string])
    transcript.isEditable = false; transcript.unregisterDraggedTypes(); transcript.textContainerInset = NSSize(width: 8, height: 8)
    transcript.backgroundColor = .controlBackgroundColor
    input.isRichText = false; input.font = .systemFont(ofSize: 13); input.allowsUndo = true; input.isAutomaticQuoteSubstitutionEnabled = false
    input.textContainerInset = NSSize(width: 4, height: 4); input.delegate = self; input.pane = self
    logScroll = makeScroll(transcript); inScroll = makeScroll(input); inScroll.borderType = .bezelBorder
    attLabel.font = .systemFont(ofSize: 11); attLabel.textColor = .secondaryLabelColor; attLabel.lineBreakMode = .byTruncatingTail
    attLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
    for (b, a) in [(clearBtn, #selector(clearAtts)), (sendBtn, #selector(send)), (newBtn, #selector(newChat))] {
      b.bezelStyle = .rounded; b.controlSize = .small; b.target = self; b.action = a
    }
    clearBtn.bezelStyle = .inline; sendBtn.keyEquivalent = ""
    let sp = NSView(); sp.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
    let attBar = NSStackView(views: [attLabel, clearBtn]), btnRow = NSStackView(views: [sp, newBtn, sendBtn])
    for v in [logScroll!, attBar, inScroll!, btnRow] { v.translatesAutoresizingMaskIntoConstraints = false; addSubview(v) }
    let edge = NSBox(); edge.boxType = .separator; edge.translatesAutoresizingMaskIntoConstraints = false; addSubview(edge)
    NSLayoutConstraint.activate([edge.leadingAnchor.constraint(equalTo: leadingAnchor), edge.topAnchor.constraint(equalTo: topAnchor), edge.bottomAnchor.constraint(equalTo: bottomAnchor), edge.widthAnchor.constraint(equalToConstant: 1)])
    NSLayoutConstraint.activate([
      logScroll.topAnchor.constraint(equalTo: topAnchor), logScroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6), logScroll.trailingAnchor.constraint(equalTo: trailingAnchor),
      logScroll.bottomAnchor.constraint(equalTo: attBar.topAnchor, constant: -6),
      attBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10), attBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      attBar.bottomAnchor.constraint(equalTo: inScroll.topAnchor, constant: -4),
      inScroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10), inScroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      inScroll.heightAnchor.constraint(equalToConstant: 76), inScroll.bottomAnchor.constraint(equalTo: btnRow.topAnchor, constant: -6),
      btnRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10), btnRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      btnRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)])
    localize()
  }
  required init?(coder: NSCoder) { fatalError() }
  func localize() {
    clearBtn.title = T("清除"); sendBtn.title = busy ? T("发送中…") : T("发送"); newBtn.title = T("新对话"); updAtt()
  }
  func updAtt() {
    attLabel.stringValue = atts.isEmpty ? T("拖入文字、图片或文件到这里") : String(format: T("附件(%ld):%@"), atts.count, atts.map { $0.name }.joined(separator: ", "))
    clearBtn.isHidden = atts.isEmpty
  }
  func add(_ who: String, _ text: String) {
    let a = NSMutableAttributedString(string: who + "\n", attributes: [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor])
    a.append(NSAttributedString(string: text + "\n\n", attributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.labelColor]))
    transcript.textStorage?.append(a); transcript.scrollToEndOfDocument(nil)
  }
  @discardableResult func ingest(_ pb: NSPasteboard) -> Bool {   // 拖入/粘贴:文件→附件,图片→附件,文字→输入框
    if let us = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !us.isEmpty {
      for u in us { if let a = loadAttach(u) { atts.append(a) } else { add("Notapple", String(format: T("无法读取该文件:%@"), u.lastPathComponent)) } }
      updAtt(); return true
    }
    if let i = NSImage(pasteboard: pb), let d = pngData(i) { atts.append(Attach(name: "image.png", text: nil, img: d, mime: "image/png")); updAtt(); return true }
    if let s = pb.string(forType: .string) { input.insertText(s, replacementRange: input.selectedRange()); return true }
    return false
  }
  override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation { .copy }
  override func performDragOperation(_ s: NSDraggingInfo) -> Bool { ingest(s.draggingPasteboard) }
  func textView(_ t: NSTextView, doCommandBy sel: Selector) -> Bool {   // Enter 发送,Shift+Enter 换行
    guard sel == #selector(NSResponder.insertNewline(_:)), !(NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false) else { return false }
    send(); return true
  }
  @objc func clearAtts() { atts = []; updAtt() }
  @objc func newChat() { hist = []; atts = []; transcript.string = ""; updAtt() }
  @objc func send() {
    let q = input.string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !busy, !q.isEmpty || !atts.isEmpty else { return }
    let m = Msg(role: "user", text: q, files: atts); hist.append(m)
    add(T("我") + (atts.isEmpty ? "" : "  [" + atts.map { $0.name }.joined(separator: ", ") + "]"), q.isEmpty ? "—" : q)
    input.string = ""; atts = []; busy = true; localize()
    let sys = T("你是嵌入在文本编辑器 Notapple 中的 AI 协作助手,回答简洁、可直接用于文档。")
    AI.ask(hist, system: sys) { [weak self] ok, r in
      guard let s = self else { return }
      s.busy = false
      if ok { s.hist.append(Msg(role: "assistant", text: r, files: [])); s.last = r; s.add("AI", r) }
      else { s.hist.removeLast(); s.input.string = q; s.atts = m.files; s.add("Notapple", r) }
      s.localize()
    }
  }
}
final class Settings: NSObject, NSWindowDelegate {
  static let shared = Settings()
  var win: NSWindow?
  let lang = NSPopUpButton(frame: .zero, pullsDown: false), prov = NSPopUpButton(frame: .zero, pullsDown: false)
  let base = NSTextField(), model = NSTextField(), key = NSSecureTextField()
  override init() {
    super.init()
    for v in [lang, prov, base, model, key] as [NSView] { v.widthAnchor.constraint(equalToConstant: 280).isActive = true }
    prov.target = self; prov.action = #selector(provChanged)
  }
  func row(_ t: String, _ v: NSView) -> NSStackView {
    let l = NSTextField(labelWithString: t); l.alignment = .right; l.widthAnchor.constraint(equalToConstant: 96).isActive = true
    let s = NSStackView(views: [l, v]); s.spacing = 10; return s
  }
  func show() { build(); win?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
  func build() {
    let d = UserDefaults.standard, p = d.integer(forKey: "ai.provider")
    if win == nil {
      let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 300), styleMask: [.titled, .closable], backing: .buffered, defer: false)
      w.isReleasedWhenClosed = false; w.delegate = self; w.isExcludedFromWindowsMenu = true; w.center(); win = w
    }
    win?.title = T("设置")
    lang.removeAllItems(); lang.addItems(withTitles: ["中文", "English"]); lang.selectItem(at: isEN ? 1 : 0)
    prov.removeAllItems(); prov.addItems(withTitles: ["Anthropic (Claude)", T("OpenAI 兼容")]); prov.selectItem(at: p)
    base.stringValue = d.string(forKey: "ai.base") ?? AI.defs[p].0; model.stringValue = d.string(forKey: "ai.model") ?? AI.defs[p].1; key.stringValue = Keychain.get() ?? ""
    let sep = NSBox(); sep.boxType = .separator; sep.widthAnchor.constraint(equalToConstant: 390).isActive = true
    let note = NSTextField(wrappingLabelWithString: T("API 密钥保存在系统钥匙串中,仅用于调用你配置的接口。") + "\n" + T("部分系统菜单项(如“窗口”)的语言需重启后切换。")); note.font = .systemFont(ofSize: 11); note.textColor = .secondaryLabelColor
    note.preferredMaxLayoutWidth = 390
    let cancel = NSButton(title: T("取消"), target: self, action: #selector(cancelTap)), apply = NSButton(title: T("应用"), target: self, action: #selector(applyTap)), ok = NSButton(title: T("确定"), target: self, action: #selector(okTap))
    cancel.keyEquivalent = "\u{1b}"; ok.keyEquivalent = "\r"
    let sp = NSView(); sp.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
    let bar = NSStackView(views: [sp, cancel, apply, ok]); bar.widthAnchor.constraint(equalToConstant: 390).isActive = true
    let st = NSStackView(views: [row(T("界面语言"), lang), sep, row(T("接口类型"), prov), row(T("接口地址"), base), row(T("模型名称"), model), row(T("API 密钥"), key), note, bar])
    st.orientation = .vertical; st.alignment = .leading; st.spacing = 12; st.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    win?.contentView = st; win?.setContentSize(st.fittingSize)
  }
  func save() {
    let d = UserDefaults.standard
    d.set(prov.indexOfSelectedItem, forKey: "ai.provider"); d.set(base.stringValue, forKey: "ai.base"); d.set(model.stringValue, forKey: "ai.model"); Keychain.set(key.stringValue)
  }
  func commit() {   // 保存全部修改(语言 + AI 配置)
    save()
    let en = lang.indexOfSelectedItem == 1
    let changed = en != isEN
    if changed { (NSApp.delegate as? App)?.applyLang(en) }
    build()
    if changed { askRestart() }
  }
  func askRestart() {   // “窗口”等系统菜单的语言由系统在启动时决定,切换后需重启
    let dirty = docs.contains { $0.win.isDocumentEdited }
    let a = NSAlert(); a.messageText = T("语言已切换"); a.informativeText = T("“窗口”等系统菜单需要重启后才会切换语言。")
    if !dirty { a.addButton(withTitle: T("立即重启")) }
    a.addButton(withTitle: T("稍后"))
    if !dirty && a.runModal() == .alertFirstButtonReturn {
      let p = Process(); p.executableURL = URL(fileURLWithPath: "/bin/sh"); p.arguments = ["-c", "sleep 1; open \"" + Bundle.main.bundlePath + "\""]
      try? p.run(); NSApp.terminate(nil)
    } else if dirty { a.runModal() }
  }
  @objc func applyTap() { commit() }                    // 应用:保存,不关闭
  @objc func okTap() { commit(); win?.close() }         // 确定:保存并关闭
  @objc func cancelTap() { win?.close() }               // 取消:不保存并关闭(下次打开会从已保存的值重新载入)
  @objc func provChanged() {
    let p = prov.indexOfSelectedItem, o = 1 - p
    if [AI.defs[o].0, ""].contains(base.stringValue) { base.stringValue = AI.defs[p].0 }
    if [AI.defs[o].1, ""].contains(model.stringValue) { model.stringValue = AI.defs[p].1 }
    save()
  }
}

// 聊天栏左缘的拖动条
final class ResizeHandle: NSView {
  var onDrag: ((CGFloat) -> Void)?
  weak var span: NSView?   // 对话显示区:只在它的高度范围内涂色,下方发送区不受影响
  override func setFrameSize(_ n: NSSize) { super.setFrameSize(n); needsDisplay = true }
  override func draw(_ dirtyRect: NSRect) {
    guard let v = span else { return }
    let r = convert(v.bounds, from: v)
    NSColor.controlBackgroundColor.setFill(); NSRect(x: 1, y: r.minY, width: max(0, bounds.width - 1), height: r.height).fill()
  }
  override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeLeftRight) }
  override func updateTrackingAreas() {
    super.updateTrackingAreas(); for a in trackingAreas { removeTrackingArea(a) }
    addTrackingArea(NSTrackingArea(rect: bounds, options: [.cursorUpdate, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
  }
  override func cursorUpdate(with e: NSEvent) { NSCursor.resizeLeftRight.set() }
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
  override func mouseDown(with e: NSEvent) {}
  override func mouseDragged(with e: NSEvent) {
    guard let cw = window?.contentView?.bounds.width else { return }
    onDrag?(max(220, min(cw - e.locationInWindow.x, cw - 300)))
  }
}

// MARK: 拖放:把文件/文件夹拖进窗口即可打开
final class DropView: NSView {
  override init(frame: NSRect) { super.init(frame: frame); registerForDraggedTypes([.fileURL]) }
  required init?(coder: NSCoder) { fatalError() }
  override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation { .copy }
  override func performDragOperation(_ s: NSDraggingInfo) -> Bool {
    guard let us = s.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !us.isEmpty else { return false }
    (NSApp.delegate as? App)?.openItems(us); return true
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
    ov.setDraggingSourceOperationMask(.copy, forLocal: true); ov.setDraggingSourceOperationMask(.copy, forLocal: false)
    view.documentView = ov; view.hasVerticalScroller = true
  }
  func outlineView(_ o: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int { item == nil ? top.count : (item as! Node).kids.count }
  func outlineView(_ o: NSOutlineView, child index: Int, ofItem item: Any?) -> Any { item == nil ? top[index] : (item as! Node).kids[index] }
  func outlineView(_ o: NSOutlineView, isItemExpandable item: Any) -> Bool { (item as! Node).isDir }
  func outlineView(_ o: NSOutlineView, viewFor c: NSTableColumn?, item: Any) -> NSView? {
    let n = item as! Node, t = NSTextField(labelWithString: n.url.lastPathComponent)
    t.lineBreakMode = .byTruncatingMiddle; t.font = .systemFont(ofSize: 12, weight: n.isDir ? .semibold : .regular); return t
  }
  func outlineView(_ o: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? { (item as! Node).url as NSURL }
  @objc func dbl() {
    guard let n = ov.item(atRow: ov.clickedRow) as? Node else { return }
    if n.isDir { ov.isItemExpanded(n) ? ov.collapseItem(n) : ov.expandItem(n) } else { (NSApp.delegate as? App)?.openURL(n.url) }
  }
}

// MARK: 文档(每个标签页一个)
var docs: [Doc] = []
var folderRoot: URL?
var readingMode = false   // 全局阅读模式:⌘. 一次切换所有 Markdown 标签页
func cur() -> Doc? { docs.first { $0.win == NSApp.mainWindow } ?? docs.last }

final class Doc: NSObject, NSWindowDelegate, NSTextViewDelegate, WKNavigationDelegate {
  let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 680), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
  let scroll = makeScroll()
  let status = NSTextField(labelWithString: "")
  let split = NSSplitView(), area = NSView(), side = Sidebar()
  let encPop = NSButton()
  let chatHost = NSView(), chatBtn = RoundButton()
  var chat: ChatPane?
  var trailFull: NSLayoutConstraint!, trailChat: NSLayoutConstraint!, chatW: NSLayoutConstraint!
  var tv: NSTextView { scroll.documentView as! NSTextView }
  var url: URL?, enc = String.Encoding.utf8, bom = false, lang: Lang?, size: CGFloat = 13, wrap = true, eol = "LF"
  var work: DispatchWorkItem?
  var reading = false, web: WKWebView?, tmp: URL?

  init(_ u: URL?) {
    super.init()
    win.title = T("未命名"); win.tabbingMode = .preferred; win.tabbingIdentifier = "ed"; win.isReleasedWhenClosed = false; win.delegate = self; win.isExcludedFromWindowsMenu = true
    let t = tv
    t.isRichText = false; t.allowsUndo = true; t.delegate = self; t.textContainerInset = NSSize(width: 4, height: 6)
    t.isAutomaticQuoteSubstitutionEnabled = false; t.isAutomaticDashSubstitutionEnabled = false
    t.isAutomaticSpellingCorrectionEnabled = false; t.isAutomaticTextReplacementEnabled = false
    (t as? EditView)?.doc = self
    setSize(13)
    scroll.hasVerticalRuler = true; scroll.rulersVisible = true; scroll.verticalRulerView = Gutter(scroll, t)
    status.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular); status.textColor = .secondaryLabelColor
    encPop.controlSize = .small; encPop.font = .systemFont(ofSize: 11); encPop.bezelStyle = .inline; encPop.target = self; encPop.action = #selector(encClick)
    encPop.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .horizontal); encPop.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .horizontal)
    let root = DropView(); win.contentView = root
    split.isVertical = true; split.dividerStyle = .thin
    scroll.translatesAutoresizingMaskIntoConstraints = false; area.addSubview(scroll)
    split.addArrangedSubview(side.view); split.addArrangedSubview(area); side.view.isHidden = true; chatHost.isHidden = true
    split.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
    chatBtn.title = ""; chatBtn.isBordered = false; chatBtn.target = self; chatBtn.action = #selector(toggleChat); chatBtn.toolTip = T("AI 协作")
    trailFull = split.trailingAnchor.constraint(equalTo: root.trailingAnchor); trailChat = split.trailingAnchor.constraint(equalTo: chatHost.leadingAnchor); chatW = chatHost.widthAnchor.constraint(equalToConstant: 300)
    for v in [split, status, encPop, chatBtn, chatHost] { v.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(v) }
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: area.topAnchor), scroll.leadingAnchor.constraint(equalTo: area.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: area.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: area.bottomAnchor),
      split.topAnchor.constraint(equalTo: root.topAnchor), split.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      trailFull, split.bottomAnchor.constraint(equalTo: encPop.topAnchor, constant: -3),
      chatHost.topAnchor.constraint(equalTo: root.topAnchor), chatHost.bottomAnchor.constraint(equalTo: split.bottomAnchor),
      chatHost.trailingAnchor.constraint(equalTo: root.trailingAnchor), chatW,
      encPop.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8), encPop.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -4),
      status.leadingAnchor.constraint(equalTo: encPop.trailingAnchor, constant: 8), status.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      status.centerYAnchor.constraint(equalTo: encPop.centerYAnchor),
      chatBtn.widthAnchor.constraint(equalToConstant: 38), chatBtn.heightAnchor.constraint(equalToConstant: 38),
      chatBtn.trailingAnchor.constraint(equalTo: area.trailingAnchor, constant: -24), chatBtn.bottomAnchor.constraint(equalTo: area.bottomAnchor, constant: -16)])
    docs.append(self)
    if let k = cur(), k !== self, docs.count > 1 { docs[docs.count - 2].win.addTabbedWindow(win, ordered: .above) }
    win.makeKeyAndOrderFront(nil); updateSidebar()
    if let u = u { load(u) } else { refresh() }
  }
  func dropFiles(_ us: [URL], at idx: Int) {
    let md = lang?.name == "Markdown" && !reading && !scroll.isHidden
    let imgs = md ? us.filter { imgExts.contains($0.pathExtension.lowercased()) } : []
    let rest = us.filter { u in !imgs.contains(u) }
    if !imgs.isEmpty { insertImages(imgs, at: idx) }
    if !rest.isEmpty { (NSApp.delegate as? App)?.openItems(rest) }
  }
  func insertImages(_ imgs: [URL], at idx: Int) {
    let dir = url?.deletingLastPathComponent()
    let body = imgs.map { u -> String in
      let alt = u.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
      var p = dir.map { relPath(u, from: $0) } ?? u.standardizedFileURL.absoluteString   // 未保存的文档用绝对路径
      if dir != nil { p = p.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? p }
      return "![" + alt + "](" + p.replacingOccurrences(of: "(", with: "%28").replacingOccurrences(of: ")", with: "%29") + ")"
    }.joined(separator: "\n\n")
    let t = tv.string as NSString; var pre = "", post = ""
    if idx > 0 { if t.character(at: idx - 1) != 10 { pre = "\n\n" } else if idx > 1 && t.character(at: idx - 2) != 10 { pre = "\n" } }
    if idx < t.length { if t.character(at: idx) != 10 { post = "\n\n" } else if idx + 1 < t.length && t.character(at: idx + 1) != 10 { post = "\n" } }
    let ins = pre + body + post
    edit(NSRange(location: idx, length: 0), ins)
    tv.setSelectedRange(NSRange(location: idx + (pre + body).utf16.count, length: 0)); win.makeFirstResponder(tv)
  }
  @objc func toggleChat() {   // 圆形按钮:唤出 / 收起右侧 AI 协作栏(固定 300pt 宽)
    if chatHost.isHidden {
      if chat == nil {
        let c = ChatPane(self); c.translatesAutoresizingMaskIntoConstraints = false; chatHost.addSubview(c)
        NSLayoutConstraint.activate([c.topAnchor.constraint(equalTo: chatHost.topAnchor), c.bottomAnchor.constraint(equalTo: chatHost.bottomAnchor),
          c.leadingAnchor.constraint(equalTo: chatHost.leadingAnchor), c.trailingAnchor.constraint(equalTo: chatHost.trailingAnchor)])
        let h = ResizeHandle(); h.translatesAutoresizingMaskIntoConstraints = false; chatHost.addSubview(h)
        NSLayoutConstraint.activate([h.leadingAnchor.constraint(equalTo: chatHost.leadingAnchor), h.topAnchor.constraint(equalTo: chatHost.topAnchor),
          h.bottomAnchor.constraint(equalTo: chatHost.bottomAnchor), h.widthAnchor.constraint(equalToConstant: 6)])
        h.onDrag = { [weak self] w in self?.chatW.constant = w }; h.span = c.logScroll
        chat = c
      }
      chatW.constant = 300; chatHost.isHidden = false; trailFull.isActive = false; trailChat.isActive = true; win.makeFirstResponder(chat?.input)
    } else {
      chatHost.isHidden = true; trailChat.isActive = false; trailFull.isActive = true
      if reading { win.makeFirstResponder(web) } else { win.makeFirstResponder(tv) }
    }
  }
  func autoLang() { lang = url.flatMap(detect) ?? sniff(tv.string) }   // 扩展名优先,否则按内容自动识别
  func syncEnc() { encPop.title = ((encs.first { $0.1 == enc && $0.2 == bom })?.0 ?? encs[0].0) + " ▾" }
  @objc func encClick() {   // 只有这个小按钮可点;弹出编码列表
    let m = NSMenu()
    for (i, e) in encs.enumerated() {
      let it = NSMenuItem(title: e.0, action: #selector(encPick(_:)), keyEquivalent: ""); it.target = self; it.tag = i
      it.state = (e.1 == enc && e.2 == bom) ? .on : .off; m.addItem(it)
    }
    m.popUp(positioning: nil, at: NSPoint(x: 0, y: encPop.bounds.maxY + 2), in: encPop)
  }
  @objc func encPick(_ i: NSMenuItem) {   // 选择编码 = 转换为该编码(保存时生效)
    let e = encs[i.tag]
    if tv.string.data(using: e.1, allowLossyConversion: false) == nil {
      let a = NSAlert(); a.messageText = String(format: T("无法用 %@ 表示当前文本中的部分字符"), e.0); a.runModal(); return
    }
    enc = e.1; bom = e.2; win.isDocumentEdited = true; refresh()
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
    if ["png", "jpg", "jpeg", "gif", "bmp", "tif", "tiff", "webp", "heic", "heif", "ico", "icns"].contains(u.pathExtension.lowercased()), let img = NSImage(contentsOf: u) {
      let rep = img.representations.first
      let w = max(1, rep?.pixelsWide ?? 0 > 0 ? rep!.pixelsWide : Int(img.size.width)), h = max(1, rep?.pixelsHigh ?? 0 > 0 ? rep!.pixelsHigh : Int(img.size.height))
      let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: w, height: h)); iv.image = img; iv.imageScaling = .scaleProportionallyUpOrDown
      let sv = NSScrollView(); sv.documentView = iv; sv.allowsMagnification = true; sv.minMagnification = 0.05; sv.maxMagnification = 16
      sv.hasVerticalScroller = true; sv.hasHorizontalScroller = true; sv.translatesAutoresizingMaskIntoConstraints = false
      scroll.isHidden = true; area.addSubview(sv)
      NSLayoutConstraint.activate([sv.topAnchor.constraint(equalTo: area.topAnchor), sv.leadingAnchor.constraint(equalTo: area.leadingAnchor),
        sv.trailingAnchor.constraint(equalTo: area.trailingAnchor), sv.bottomAnchor.constraint(equalTo: area.bottomAnchor)])
      sv.magnification = min(1, 900 / CGFloat(w), 600 / CGFloat(h))
      status.stringValue = "\(u.pathExtension.uppercased())  |  \(w)×\(h) px  |  " + ByteCountFormatter.string(fromByteCount: Int64(d.count), countStyle: .file)
      return
    }
    if u.pathExtension.lowercased() == "pdf" {
      let p = PDFView(); p.document = PDFDocument(url: u); p.autoScales = true
      p.translatesAutoresizingMaskIntoConstraints = false; scroll.isHidden = true; encPop.isHidden = true; status.stringValue = T("PDF(只读预览)")
      area.addSubview(p)
      NSLayoutConstraint.activate([p.topAnchor.constraint(equalTo: area.topAnchor), p.leadingAnchor.constraint(equalTo: area.leadingAnchor),
        p.trailingAnchor.constraint(equalTo: area.trailingAnchor), p.bottomAnchor.constraint(equalTo: area.bottomAnchor)])
      return
    }
    if ["png", "jpg", "jpeg", "gif", "bmp", "tif", "tiff", "webp", "heic", "heif", "ico", "icns"].contains(u.pathExtension.lowercased()), let img = NSImage(contentsOf: u) {
      let v = DragImageView(image: img); v.fileURL = u; v.isEditable = false; v.imageScaling = .scaleProportionallyDown; v.animates = true
      for o: NSLayoutConstraint.Orientation in [.horizontal, .vertical] { v.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1), for: o); v.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: o) }
      v.translatesAutoresizingMaskIntoConstraints = false; scroll.isHidden = true; encPop.isHidden = true; area.addSubview(v)
      NSLayoutConstraint.activate([v.topAnchor.constraint(equalTo: area.topAnchor), v.leadingAnchor.constraint(equalTo: area.leadingAnchor),
        v.trailingAnchor.constraint(equalTo: area.trailingAnchor), v.bottomAnchor.constraint(equalTo: area.bottomAnchor)])
      let px = (img.representations.first as? NSBitmapImageRep).map { ($0.pixelsWide, $0.pixelsHigh) } ?? (Int(img.size.width), Int(img.size.height))
      status.stringValue = String(format: T("图片  |  %ld × %ld 像素  |  %@"), px.0, px.1, ByteCountFormatter.string(fromByteCount: Int64(d.count), countStyle: .file))
      return
    }
    guard let (s, e, b) = decode(d) else {
      let a = NSAlert(); a.messageText = String(format: T("无法作为文本打开:%@"), u.lastPathComponent); a.informativeText = T("文件看起来是二进制。"); a.runModal(); win.close(); return
    }
    enc = e; bom = b; eol = s.contains("\r\n") ? "CRLF" : (s.contains("\r") ? "CR" : "LF")
    tv.string = s; autoLang(); highlight(); win.isDocumentEdited = false; refresh()
    if readingMode { setReading(true) }   // 新打开的 Markdown 跟随全局模式
  }
  func save(_ asNew: Bool) {
    var u = url
    if u == nil || asNew { let p = NSSavePanel(); guard p.runModal() == .OK else { return }; u = p.url }
    guard let t = u else { return }
    guard var d = tv.string.data(using: enc, allowLossyConversion: false) else {
      let a = NSAlert(); a.messageText = T("当前编码无法表示文本中的部分字符,未写入文件"); a.runModal(); return
    }
    if bom && enc == .utf8 { d = Data([0xEF, 0xBB, 0xBF]) + d }
    do { try d.write(to: t, options: .atomic) } catch { NSAlert(error: error).runModal(); return }
    url = t; win.title = t.lastPathComponent; win.representedURL = t; win.isDocumentEdited = false
    autoLang(); highlight(); refresh()
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
  func setReading(_ on: Bool) {   // 阅读 / 编辑(仅 Markdown)
    if !on {
      guard reading else { return }
      web?.removeFromSuperview(); web = nil; if let t = tmp { try? FileManager.default.removeItem(at: t) }; tmp = nil
      reading = false; scroll.isHidden = false; win.makeFirstResponder(tv); refresh(); return
    }
    guard !reading, lang?.name == "Markdown", !scroll.isHidden else { return }
    let cfg = WKWebViewConfiguration(); cfg.defaultWebpagePreferences.allowsContentJavaScript = false
    let w = WKWebView(frame: .zero, configuration: cfg); w.navigationDelegate = self
    w.translatesAutoresizingMaskIntoConstraints = false; area.addSubview(w)
    NSLayoutConstraint.activate([w.topAnchor.constraint(equalTo: area.topAnchor), w.leadingAnchor.constraint(equalTo: area.leadingAnchor),
      w.trailingAnchor.constraint(equalTo: area.trailingAnchor), w.bottomAnchor.constraint(equalTo: area.bottomAnchor)])
    let t = FileManager.default.temporaryDirectory.appendingPathComponent("Notapple-\(UUID().uuidString).html")
    try? mdPage(tv.string, url).write(to: t, atomically: true, encoding: .utf8)
    w.loadFileURL(t, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    web = w; tmp = t; reading = true; scroll.isHidden = true; win.makeFirstResponder(w); refresh()
  }
  func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard a.navigationType == .linkActivated, let u = a.request.url else { decisionHandler(.allow); return }
    decisionHandler(.cancel)
    if u.isFileURL { if u.fragment == nil, FileManager.default.fileExists(atPath: u.path) { (NSApp.delegate as? App)?.openItems([u]) } }
    else if ["http", "https", "mailto"].contains(u.scheme ?? "") { NSWorkspace.shared.open(u) }
  }
  func refresh() {
    if reading { status.stringValue = T("阅读模式(⌘. 返回编辑)"); return }
    let s = tv.string as NSString, p = tv.selectedRange().location
    var ln = 1, last = 0, i = 0
    for u in s.substring(to: min(p, s.length)).utf16 { i += 1; if u == 10 { ln += 1; last = i } }
    syncEnc()
    status.stringValue = String(format: T("行 %ld, 列 %ld  |  %ld 字符  |  %@  |  %@"), ln, p - last + 1, s.length, lang?.name ?? T("纯文本"), eol)
  }
  func textDidChange(_ n: Notification) {
    win.isDocumentEdited = true; refresh(); work?.cancel()
    let w = DispatchWorkItem { [weak self] in self?.autoLang(); self?.highlight(); self?.refresh() }; work = w
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
  func windowWillClose(_ n: Notification) { docs.removeAll { $0 === self }; if let t = tmp { try? FileManager.default.removeItem(at: t) } }
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
final class App: NSObject, NSApplicationDelegate, NSMenuDelegate, NSMenuItemValidation {
  func openURL(_ u: URL) {
    if let d = docs.first(where: { $0.url == u }) { d.win.makeKeyAndOrderFront(nil); return }
    if let c = cur(), c.url == nil, !c.win.isDocumentEdited, c.tv.string.isEmpty { c.load(u) } else { _ = Doc(u) }
  }
  func openItems(_ us: [URL]) {
    for u in us {
      if (try? u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true { folderRoot = u; docs.forEach { $0.updateSidebar() } } else { openURL(u) }
    }
  }
  func application(_ a: NSApplication, openFiles f: [String]) { openItems(f.map { URL(fileURLWithPath: $0) }); a.reply(toOpenOrPrint: .success) }
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
    let a = sub("Notapple"); add(a, T("设置…"), #selector(openSettings), ","); a.addItem(.separator()); add(a, T("退出 Notapple"), #selector(NSApplication.terminate(_:)), "q")
    let f = sub(T("文件"))
    add(f, T("新建标签页"), #selector(newDoc), "n"); add(f, T("打开…"), #selector(openDlg), "o"); add(f, T("关闭文件夹"), #selector(closeFolder))
    add(f, T("保存"), #selector(save), "s"); add(f, T("另存为…"), #selector(saveAs), "s", [.command, .shift]); add(f, T("关闭标签页"), #selector(NSWindow.performClose(_:)), "w")
    let e = sub(T("编辑"))
    add(e, T("撤销"), #selector(undoCmd), "z"); add(e, T("重做"), #selector(redoCmd), "z", [.command, .shift])
    add(e, T("剪切"), #selector(NSText.cut(_:)), "x"); add(e, T("拷贝"), #selector(NSText.copy(_:)), "c")
    add(e, T("粘贴"), #selector(NSText.paste(_:)), "v"); add(e, T("全选"), #selector(NSText.selectAll(_:)), "a")
    e.addItem(.separator())
    add(e, T("查找 / 替换…"), #selector(find), "f")
    e.addItem(.separator())
    add(e, T("删除重复行"), #selector(dedupe)); add(e, T("去除行尾空白"), #selector(trim))
    let v = sub(T("视图"))
    add(v, T("自动换行"), #selector(toggleWrap), "w", [.option]); add(v, T("放大"), #selector(bigger), "+"); add(v, T("缩小"), #selector(smaller), "-"); add(v, T("切换阅读/编辑模式"), #selector(toggleRead), "."); add(v, T("AI 协作"), #selector(toggleAI), "a", [.command, .option])
    let w = sub(T("窗口")); w.delegate = self; NSApp.windowsMenu = w   // 仅保留系统提供的 Fill / Center / Move & Resize / Full Screen Tile
  }
  func menuWillOpen(_ m: NSMenu) { prune(m) }
  func menuNeedsUpdate(_ m: NSMenu) { prune(m) }
  func prune(_ m: NSMenu) {   // 去掉系统自动加入的 最小化/缩放/标签页/窗口列表 等项
    let bad: Set<String> = ["performMiniaturize:", "performZoom:", "arrangeInFront:", "selectNextTab:", "selectPreviousTab:", "moveTabToNewWindow:", "mergeAllWindows:", "toggleTabBar:", "toggleTabOverview:", "makeKeyAndOrderFront:"]
    for it in m.items.reversed() where (it.action.map { bad.contains(NSStringFromSelector($0)) } ?? false) || it.target is NSWindow { m.removeItem(it) }
    while let f = m.items.first, f.isSeparatorItem { m.removeItem(f) }
    while let l = m.items.last, l.isSeparatorItem { m.removeItem(l) }
    var k = 1; while k < m.items.count { if m.items[k].isSeparatorItem && m.items[k - 1].isSeparatorItem { m.removeItem(at: k) } else { k += 1 } }
  }
  @objc func closeFolder() { folderRoot = nil; docs.forEach { $0.updateSidebar() } }
  func applyLang(_ en: Bool) {
    isEN = en; UserDefaults.standard.set(en ? "en" : "zh", forKey: "ui"); UserDefaults.standard.set(en ? ["en"] : ["zh-Hans", "en"], forKey: "AppleLanguages"); buildMenu()
    for d in docs { if d.url == nil { d.win.title = T("未命名") }; d.refresh(); d.chat?.localize(); d.chatBtn.toolTip = T("AI 协作") }
    Finder.shared.localize()
  }
  @objc func openSettings() { Settings.shared.show() }
  @objc func toggleAI() { cur()?.toggleChat() }
  func ur() -> UndoManager? { (NSApp.keyWindow?.firstResponder as? NSTextView)?.undoManager }   // 作用于当前输入框(编辑区 / 聊天框 / 设置)
  @objc func undoCmd() { ur()?.undo() }
  @objc func redoCmd() { ur()?.redo() }
  func validateMenuItem(_ i: NSMenuItem) -> Bool {
    if i.action == #selector(undoCmd) { return ur()?.canUndo ?? false }
    if i.action == #selector(redoCmd) { return ur()?.canRedo ?? false }
    return true
  }
  @objc func newDoc() { _ = Doc(nil) }
  @objc func openDlg() {   // 一个入口同时打开文件和文件夹
    let p = NSOpenPanel(); p.canChooseFiles = true; p.canChooseDirectories = true; p.allowsMultipleSelection = true
    if p.runModal() == .OK { openItems(p.urls) }
  }
  @objc func save() { cur()?.save(false) }
  @objc func saveAs() { cur()?.save(true) }
  @objc func find() { Finder.shared.show() }
  func xf(_ f: (String) -> String) {
    guard let d = cur() else { return }; var r = d.tv.selectedRange(); let s = d.tv.string as NSString
    if r.length == 0 { r = NSRange(location: 0, length: s.length) }
    d.edit(r, f(s.substring(with: r)))
  }
  @objc func dedupe() { xf { var seen = Set<String>(); return $0.components(separatedBy: "\n").filter { seen.insert($0).inserted }.joined(separator: "\n") } }
  @objc func trim() { xf { $0.components(separatedBy: "\n").map { l in l.replacingOccurrences(of: #"[ \t]+$"#, with: "", options: .regularExpression) }.joined(separator: "\n") } }
  @objc func toggleWrap() { guard let d = cur() else { return }; d.setWrap(!d.wrap) }
  @objc func toggleRead() {
    guard let c = cur() else { return }
    let md = docs.filter { $0.lang?.name == "Markdown" && ($0.reading || !$0.scroll.isHidden) }
    guard !md.isEmpty else { NSSound.beep(); return }
    readingMode = !(c.lang?.name == "Markdown" ? c.reading : readingMode)
    md.forEach { $0.setReading(readingMode) }
  }
  @objc func bigger() { if let d = cur() { d.setSize(d.size + 1) } }
  @objc func smaller() { if let d = cur() { d.setSize(d.size - 1) } }
}

if CommandLine.arguments.count > 2, CommandLine.arguments[1] == "--make-icon" { _ = NSApplication.shared; writeIconset(CommandLine.arguments[2]); exit(0) }
UserDefaults.standard.set(isEN ? ["en"] : ["zh-Hans", "en"], forKey: "AppleLanguages")   // 让系统提供的菜单项(窗口 / Fill 等)与应用语言一致
let app = NSApplication.shared; let delegate = App()
app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
