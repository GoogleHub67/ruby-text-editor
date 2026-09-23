require 'tk'
require 'tkextlib/tile'

class FullNotepadPlusPlus
  def initialize
    @root = TkRoot.new { title "RubyCode++ Professional v2.0" }
    @root.geometry("1100x700")
    
    @tabs = {} 
    @tab_counter = 0
    @current_theme = :dark

    setup_themes
    create_menu
    create_global_toolbar
    create_find_replace_drawer
    create_main_workspace
    
    new_tab
  end

  def setup_themes
    TkTkwin.theme_use('clam') rescue nil
    
    @themes = {
      dark:    { bg: '#1E1E1E', fg: '#D4D4D4', line_bg: '#252526', line_fg: '#858585', keyword: '#569CD6', string: '#CE9178', comment: '#6A9955' },
      light:   { bg: '#FFFFFF', fg: '#000000', line_bg: '#F0F0F0', line_fg: '#A0A0A0', keyword: '#0000FF', string: '#A31515', comment: '#008000' },
      monokai: { bg: '#272822', fg: '#F8F8F2', line_bg: '#3E3D32', line_fg: '#75715E', keyword: '#F92672', string: '#E6DB74', comment: '#75715E' }
    }
    @code_font = TkFont.new(family: "Consolas", size: 11)
  end

  def create_menu
    menu_bar = TkMenu.new(@root)
    @root.menu(menu_bar)

    file_menu = TkMenu.new(menu_bar, tearoff: false)
    file_menu.add('command', label: 'New File (Ctrl+N)', command: proc { new_tab })
    file_menu.add('command', label: 'Open File... (Ctrl+O)', command: proc { open_file })
    file_menu.add('command', label: 'Save (Ctrl+S)', command: proc { save_file })
    file_menu.add('command', label: 'Close Tab (Ctrl+W)', command: proc { close_current_tab })
    menu_bar.add('cascade', menu: file_menu, label: 'File')

    edit_menu = TkMenu.new(menu_bar, tearoff: false)
    edit_menu.add('command', label: 'Find & Replace (Ctrl+F)', command: proc { toggle_find_drawer })
    edit_menu.add('command', label: 'Document Summary Statistics', command: proc { show_document_stats })
    menu_bar.add('cascade', menu: edit_menu, label: 'Search')

    view_menu = TkMenu.new(menu_bar, tearoff: false)
    view_menu.add('radiobutton', label: 'VS Dark Theme', command: proc { change_theme(:dark) })
    view_menu.add('radiobutton', label: 'Classic Light Theme', command: proc { change_theme(:light) })
    view_menu.add('radiobutton', label: 'Monokai Retro Theme', command: proc { change_theme(:monokai) })
    menu_bar.add('cascade', menu: view_menu, label: 'View Settings')
  end

  def create_global_toolbar
    @toolbar = Tk::Tile::Frame.new(@root).pack(side: 'top', fill: 'x')
    Tk::Tile::Button.new(@toolbar) { text "📄 New"; command proc { new_tab } }.pack(side: 'left', padx: 2)
    Tk::Tile::Button.new(@toolbar) { text "📂 Open"; command proc { open_file } }.pack(side: 'left', padx: 2)
    Tk::Tile::Button.new(@toolbar) { text "💾 Save"; command proc { save_file } }.pack(side: 'left', padx: 2)
    Tk::Tile::Button.new(@toolbar) { text "📊 Stats"; command proc { show_document_stats } }.pack(side: 'left', padx: 5)
  end

  def create_find_replace_drawer
    @find_panel = Tk::Tile::Frame.new(@root)
    Tk::Tile::Label.new(@find_panel) { text " 🔍 Search: " }.pack(side: 'left')
    @find_input = Tk::Tile::Entry.new(@find_panel).pack(side: 'left', fill: 'x', expand: true, padx: 4)
    Tk::Tile::Button.new(@find_panel) { text "Highlight All"; command proc { execute_global_search } }.pack(side: 'left', padx: 4)
  end

  def create_main_workspace
    @notebook = Tk::Tile::Notebook.new(@root).pack(fill: 'both', expand: true)
    @notebook.bind('<<NotebookTabChanged>>') { update_editor_environment }
  end

  def new_tab(title = "untitled.#{@tab_counter += 1}", content = "")
    tab_frame = Tk::Tile::Frame.new(@notebook)
    
    line_canvas = TkCanvas.new(tab_frame) do
      width 45
      borderwidth 0
      highlightthickness 0
    end
    line_canvas.pack(side: 'left', fill: 'y')

    scrollbar = Tk::Tile::Scrollbar.new(tab_frame).pack(side: 'right', fill: 'y')

    text_area = TkText.new(tab_frame) do
      wrap 'none'
      undo true
      padx 5
      pady 5
    end
    text_area.pack(side: 'left', fill: 'both', expand: true)
    
    text_area.yscrollbar(scrollbar)
    text_area.insert('1.0', content)

    text_area.bind('KeyRelease') { sync_line_numbers(text_area, line_canvas); apply_highlighter(text_area) }
    text_area.bind('ButtonRelease') { update_editor_environment }

    @notebook.add(tab_frame, text: title)
    @notebook.select(tab_frame)

    @tabs[tab_frame.path] = { text_area: text_area, line_canvas: line_canvas, file_path: nil }
    
    change_theme(@current_theme)
    sync_line_numbers(text_area, line_canvas)
  end

  def sync_line_numbers(txt, canvas)
    canvas.delete('all')
    theme = @themes[@current_theme]
    
    i = 1
    loop do
      pos = txt.index("#{i}.0")
      dline = txt.dlineinfo(pos)
      break unless dline
      
      y = dline
      canvas.create(TkcText, 35, y + 2, text: i.to_s, anchor: 'ne', fill: theme[:line_fg], font: @code_font)
      i += 1
    end
  end

  def apply_highlighter(txt)
    theme = @themes[@current_theme]
    ['kw', 'str', 'cmt'].each { |tag| txt.tag_remove(tag, '1.0', 'end') }
    
    TkTextTag.new(txt, 'kw') { foreground theme[:keyword]; font TkFont.new(family: "Consolas", size: 11, weight: 'bold') }
    TkTextTag.new(txt, 'cmt') { foreground theme[:comment] }
    TkTextTag.new(txt, 'str') { foreground theme[:string] }

    raw = txt.get('1.0', 'end')
    
    raw.scan(/(["'])(?:(?=(\\?))\2.)*?\1/) do
      txt.tag_add('str', "1.0 + #{Regexp.last_match.begin(0)} chars", "1.0 + #{Regexp.last_match.end(0)} chars")
    end
    raw.scan(/\b(def|class|end|if|else|return|require|yield|module|while|for)\b/) do
      txt.tag_add('kw', "1.0 + #{Regexp.last_match.begin(0)} chars", "1.0 + #{Regexp.last_match.end(0)} chars")
    end
    raw.scan(/#.*/) do
      txt.tag_add('cmt', "1.0 + #{Regexp.last_match.begin(0)} chars", "1.0 + #{Regexp.last_match.end(0)} chars")
    end
  end

  def change_theme(theme_key)
    @current_theme = theme_key
    theme = @themes[theme_key]
    
    @tabs.each do |_path, structures|
      t = structures[:text_area]
      c = structures[:line_canvas]
      
      t.configure(background: theme[:bg], foreground: theme[:fg], insertbackground: theme[:fg], font: @code_font)
      c.configure(background: theme[:line_bg])
      
      apply_highlighter(t)
      sync_line_numbers(t, c)
    end
  end

  def show_document_stats
    info = current_tab_info
    return unless info
    
    text_data = info[:text_area].get('1.0', 'end-1c')
    char_count = text_data.length
    word_count = text_data.split(/\s+/).reject(&:empty?).size
    line_count = text_data.lines.count

    Tk.messageBox(
      title: 'Document Statistics',
      message: "Total Characters: #{char_count}\nWords Tracked: #{word_count}\nTotal Lines: #{line_count}",
      type: 'ok', icon: 'info'
    )
  end

  def execute_global_search
    info = current_tab_info
    return unless info
    txt = info[:text_area]
    query = @find_input.get
    
    txt.tag_remove('find_match', '1.0', 'end')
    return if query.empty?

    TkTextTag.new(txt, 'find_match') { background '#FF9600'; foreground '#000000' }
    
    start_pos = '1.0'
    loop do
      pos = txt.search(query, start_pos, 'end')
      break if pos.empty?
      end_pos = txt.index("#{pos} + #{query.length} chars")
      txt.tag_add('find_match', pos, end_pos)
      start_pos = end_pos
    end
  end

  def current_tab_info
    active = @notebook.select
    active.empty? ? nil : @tabs[active]
  end

  def toggle_find_drawer
    @find_panel.pack_info.empty? ? @find_panel.pack(side: 'top', fill: 'x') : @find_panel.unpack
  end

  def update_editor_environment
    info = current_tab_info
    return unless info
    sync_line_numbers(info[:text_area], info[:line_canvas])
  end

  def open_file
    path = Tk.getOpenFile
    return if path.empty?
    new_tab(File.basename(path), File.read(path))
    @tabs[@notebook.select][:file_path] = path
  end

  def save_file
    info = current_tab_info
    return unless info
    if info[:file_path].nil?
      path = Tk.getSaveFile
      return if path.empty?
      info[:file_path] = path
    end
    File.write(info[:file_path], info[:text_area].get('1.0', 'end-1c'))
    @notebook.tab(@notebook.select, text: File.basename(info[:file_path]))
  end

  def close_current_tab
    active = @notebook.select
    return if active.empty?
    @tabs.delete(active)
    @notebook.forget(active)
    new_tab if @tabs.empty?
  end
end

Tk.mainloop { FullNotepadPlusPlus.new }
