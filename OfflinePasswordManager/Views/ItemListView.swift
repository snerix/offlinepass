import SwiftUI



struct CategoryChipBar: View {
    let categories: [ItemCategory]
    let items: [PasswordItem]
    @Binding var selectedCategory: ItemCategory?
    let onSelect: (ItemCategory) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    let count = items.filter { $0.category == category }.count
                    CategoryChip(
                        title: category.rawValue,
                        count: count,
                        isSelected: selectedCategory == category
                    ) {
                        onSelect(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.primary.opacity(0.2) : Color.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.primary.opacity(0.08))
            .foregroundColor(isSelected ? .white : .gray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PasswordListContent: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ForEach(ItemCategory.allCases, id: \.self) { category in
            let categoryItems = viewModel.filteredItems.filter { $0.category == category }
            if !categoryItems.isEmpty {
                Section(header: Text(category.rawValue).foregroundColor(.gray)) {
                    ForEach(categoryItems) { item in
                        NavigationLink(destination: ItemDetailView(viewModel: viewModel, item: item)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.headline).foregroundColor(.primary)
                                if !item.account.isEmpty {
                                    Text(item.account).font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.primary.opacity(0.05))
                    }
                    .onDelete { indexSet in
                        for item in indexSet.map({ categoryItems[$0] }) {
                            viewModel.delete(item: item)
                        }
                    }
                }
                .id(category)
            }
        }
    }
}

struct MainListView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var selectedCategory: ItemCategory?
    @State private var isSearching = false
    @FocusState private var searchFocused: Bool
    
    @AppStorage("displayMode") private var displayMode: DisplayMode = .system
    @AppStorage("appFontSize") private var appFontSize: AppFontSize = .standard
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    
    private var activeCategories: [ItemCategory] {
        ItemCategory.allCases.filter { cat in
            viewModel.filteredItems.contains { $0.category == cat }
        }
    }
    
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationView {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        if isSearching {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                TextField("搜索", text: $viewModel.searchText)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .focused($searchFocused)
                                if !viewModel.searchText.isEmpty {
                                    Button {
                                        viewModel.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button("取消") {
                                viewModel.searchText = ""
                                isSearching = false
                                searchFocused = false
                            }
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        } else {
                            Text("密本")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button {
                                isSearching = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    searchFocused = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.primary.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { showingAddSheet = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color.primary.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.primary.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { viewModel.lock() }) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                    .padding(8)
                                    .background(Color.primary.opacity(0.08))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .animation(.easeInOut(duration: 0.25), value: isSearching)
                    
                    if !activeCategories.isEmpty {
                        CategoryChipBar(
                            categories: activeCategories,
                            items: viewModel.filteredItems,
                            selectedCategory: $selectedCategory
                        ) { category in
                            selectedCategory = category
                            withAnimation {
                                scrollProxy?.scrollTo(category, anchor: .top)
                            }
                        }
                    }
                    
                    ScrollViewReader { proxy in
                        List {
                            PasswordListContent(viewModel: viewModel)
                                .listRowSeparatorTint(Color.primary.opacity(0.08))
                        }
                        .scrollContentBackground(.hidden)
                        #if os(iOS)
                        .listStyle(.insetGrouped)
                        #else
                        .listStyle(.sidebar)
                        #endif
                        #if os(iOS)
                        .scrollDismissesKeyboard(.interactively)
                        #endif
                        .onAppear { scrollProxy = proxy }
                        .onChange(of: selectedCategory) { _ in }
                    }
                }
            .background(Color(UIColor.systemBackground))
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif

            .sheet(isPresented: $showingAddSheet) {
                ItemEditView(viewModel: viewModel, isNew: true)
                    .preferredColorScheme(displayMode.colorScheme)
                    .dynamicTypeSize(appFontSize.dynamicTypeSize)
                    .environment(\.locale, appLanguage.locale ?? Locale.current)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }
}

struct ItemDetailView: View {
    @ObservedObject var viewModel: AppViewModel
    let item: PasswordItem
    @State private var isShowingPassword = true
    @State private var showingEditSheet = false
    @State private var copyMessage: String?
    
    @AppStorage("displayMode") private var displayMode: DisplayMode = .system
    @AppStorage("appFontSize") private var appFontSize: AppFontSize = .standard
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                LabeledContent("标题", value: item.title)
                LabeledContent("账号", value: item.account)
                LabeledContent("分类", value: item.category.rawValue)
            }
            
            Section(header: Text("机密信息")) {
                HStack {
                    if isShowingPassword {
                        Text(item.value)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        Text("••••••••")
                    }
                    Spacer()
                    Button(action: { isShowingPassword.toggle() }) {
                        Image(systemName: isShowingPassword ? "eye.slash" : "eye")
                    }
                }
                
                Button(action: {
                    #if os(iOS)
                    UIPasteboard.general.string = item.value
                    #else
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(item.value, forType: .string)
                    #endif
                    withAnimation {
                        copyMessage = "已复制"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copyMessage = nil }
                    }
                }) {
                    HStack {
                        Text("复制密码")
                        if let msg = copyMessage {
                            Spacer()
                            Text(msg).foregroundColor(.green).font(.caption)
                        }
                    }
                }
            }
            
            if !item.note.isEmpty {
                Section(header: Text("备注")) {
                    Text(item.note)
                }
            }
            
            Section {
                Text("更新时间: \(item.updateTime.formatted())")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle(item.title)
        .toolbar {
            Button("编辑") { showingEditSheet = true }
        }
        .sheet(isPresented: $showingEditSheet) {
            ItemEditView(viewModel: viewModel, item: item, isNew: false)
                .preferredColorScheme(displayMode.colorScheme)
                .dynamicTypeSize(appFontSize.dynamicTypeSize)
                .environment(\.locale, appLanguage.locale ?? Locale.current)
        }
    }
}

struct ItemEditView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State var item: PasswordItem
    var isNew: Bool
    
    init(viewModel: AppViewModel, item: PasswordItem? = nil, isNew: Bool) {
        self.viewModel = viewModel
        self._item = State(initialValue: item ?? PasswordItem(title: "", value: ""))
        self.isNew = isNew
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("必填")) {
                    TextField("标题 (如: 招商银行)", text: $item.title)
                    TextField("账号/用户名", text: $item.account)
                    SecureField("密码/机密内容", text: $item.value)
                }
                
                Section(header: Text("属性")) {
                    Picker("分类", selection: $item.category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $item.note)
                        .frame(height: 100)
                }
            }
            .navigationTitle(isNew ? "新建" : "编辑")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var savingItem = item
                        savingItem.updateTime = Date()
                        if isNew {
                            viewModel.addItem(savingItem)
                        } else {
                            viewModel.updateItem(savingItem)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(item.title.isEmpty || item.value.isEmpty)
                }
            }
        }
    }
}
