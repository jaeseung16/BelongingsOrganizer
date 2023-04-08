//
//  ItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var item: Item
    @State private var kind = [Kind]()
    @State private var brand: BrandDTO?
    @State private var seller: SellerDTO?
    
    @State private var isEditing = false
    @State private var isEdited = false
    
    @State var imageData: Data?
    @State var name = ""
    @State var quantity: Int = 0
    @State var buyPrice = 0.0
    @State var sellPrice = 0.0
    @State var buyCurrency: String = "USD"
    @State var sellCurrency: String = "USD"
    @State var note: String = ""
    @State var obtained = Date()
    @State var disposed = Date()
    
    @State var presentPhotoView = false
    @State var presentChooseKindView = false
    @State var presentChooseBrandView = false
    @State var presentChooseSellerView = false
    @State var presentChooseBuyCurrencyView = false
    @State var presentChooseSellCurrencyView = false
    @State var presentObtainedDatePickerView = false
    @State var presentDisposedDatePickerView = false
    
    @State private var isObtainedDateEdited = false
    @State private var isDisposedDateEdited = false
    
    @FocusState private var quantityIsFocused: Bool
    @FocusState private var buyPriceIsFocused: Bool
    @FocusState private var sellPriceIsFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                itemInfo()
                
                Divider()
                
                footer()
            }
            .navigationTitle(name)
            .padding()
            .sheet(isPresented: $presentChooseKindView, content: {
                #if os(macOS)
                ChooseKindView(selectedKinds: $kind)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: kind) { _ in
                        isEdited = true
                    }
                #else
                ChooseKindView(selectedKinds: $kind)
                    .onChange(of: kind) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseBrandView, content: {
                #if os(macOS)
                ChooseBrandView(brand: $brand)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: brand) { _ in
                        isEdited = true
                    }
                #else
                ChooseBrandView(brand: $brand)
                    .onChange(of: brand) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseSellerView, content: {
                #if os(macOS)
                ChooseSellerView(seller: $seller)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: seller) { _ in
                        isEdited = true
                    }
                #else
                ChooseSellerView(seller: $seller)
                    .onChange(of: seller) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseBuyCurrencyView, content: {
                #if os(macOS)
                ChooseCurrencyView(currency: $buyCurrency)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.2 * geometry.size.height)
                    .onChange(of: buyCurrency) { _ in
                        isEdited = true
                    }
                #else
                ChooseCurrencyView(currency: $buyCurrency)
                    .onChange(of: buyCurrency) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseSellCurrencyView, content: {
                #if os(macOS)
                ChooseCurrencyView(currency: $sellCurrency)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.2 * geometry.size.height)
                    .onChange(of: sellCurrency) { _ in
                        isEdited = true
                    }
                #else
                ChooseCurrencyView(currency: $sellCurrency)
                    .onChange(of: sellCurrency) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentPhotoView, content: {
                #if os(macOS)
                EditPhotoView(originalImage: item.image, image: $imageData)
                    .environmentObject(viewModel)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.5 * geometry.size.height)
                    .onChange(of: imageData) { _ in
                        isEdited = true
                    }
                #else
                EditPhotoView(originalImage: item.image, image: $imageData)
                    .environmentObject(viewModel)
                    .onChange(of: imageData) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentObtainedDatePickerView, content: {
                EditDateView(date: $obtained, originalDate: item.obtained, isEdited: $isObtainedDateEdited)
                    .onChange(of: obtained) { _ in
                        isEdited = true
                    }
            })
            .sheet(isPresented: $presentDisposedDatePickerView, content: {
                EditDateView(date: $disposed, originalDate: item.disposed, isEdited: $isDisposedDateEdited)
                    .onChange(of: disposed) { _ in
                        isEdited = true
                    }
            })
        }
    }
    
    private func reset() -> Void {
        imageData = item.image
        name = item.name ?? ""
        quantity = Int(item.quantity)
        buyPrice = item.buyPrice
        sellPrice = item.sellPrice
        buyCurrency = item.buyCurrency ?? "USD"
        sellCurrency = item.sellCurrency ?? "USD"
        note = item.note ?? ""
        obtained = item.obtained ?? Date()
        disposed = item.disposed ?? Date()
        
        kind.removeAll()
        brand = nil
        seller = nil
        
        isEditing = false
        isEdited = false
        isObtainedDateEdited = false
        isDisposedDateEdited = false
    }
    
    private func header() -> some View {
        DetailHeaderView(isEdited: $isEdited) {
            reset()
        } update: {
            if !kind.isEmpty {
                item.kind?.forEach {
                    if let kind = $0 as? Kind {
                        kind.removeFromItems(item)
                    }
                }
                kind.forEach { $0.addToItems(item) }
            }
            
            if let brand = brand {
                item.brand?.forEach {
                    if let brand = $0 as? Brand {
                        brand.removeFromItems(item)
                    }
                }
                
                if let id = brand.id, let brandEntity: Brand = viewModel.get(entity: .Brand, id: id) {
                    brandEntity.addToItems(item)
                }
            }
            
            if let seller = seller {
                item.seller?.forEach {
                    if let seller = $0 as? Seller {
                        seller.removeFromItems(item)
                    }
                }
                
                if let id = seller.id, let sellerEntity: Seller = viewModel.get(entity: .Seller, id: id) {
                    sellerEntity.addToItems(item)
                }
            }
            
            viewModel.itemDTO = ItemDTO(id: item.uuid,
                                        name: name,
                                        note: note,
                                        quantity: Int64(quantity),
                                        buyPrice: buyPrice,
                                        sellPrice: sellPrice,
                                        buyCurrency: buyCurrency,
                                        sellCurrency: sellCurrency,
                                        obtained: isObtainedDateEdited ? obtained : item.obtained,
                                        disposed: isDisposedDateEdited ? disposed : item.disposed,
                                        image: imageData ?? item.image)
            isEdited = false
        }
    }
    
    private var quantityFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        return formatter
    }
    
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    #if os(macOS)
    private var image: NSImage? {
        if let data = imageData {
            return NSImage(data: data)
        } else if let data = item.image {
            return NSImage(data: data)
        } else {
            return nil
        }
    }
    #else
    private var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        } else if let data = item.image {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    #endif
    
    private func itemInfo() -> some View {
        List {
            ForEach(ItemProperty.allCases) { property in
                switch property {
                case .name:
                    nameView()
                case .photo:
                    photoView()
                case .note:
                    noteView()
                case .quantity:
                    quantityView()
                case .category:
                    categoryView()
                case .brand:
                    brandView()
                case .seller:
                    sellerView()
                case .obtained:
                    obtainedView()
                case .buyPrice:
                    buyPriceView()
                case .disposed:
                    disposedView()
                case .sellPrice:
                    sellPriceView()
                }
            }
        }
    }
    
    private func nameView() -> some View {
        HStack {
            SectionTitleView(title: "NAME")
            
            Spacer()
            
            TextField(item.name ?? "", text: $name, prompt: nil)
                .onSubmit {
                    isEdited = true
                }
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func photoView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: "PHOTO")
                
                Spacer()
                
                Button {
                    presentPhotoView = true
                    viewModel.addItemViewModel.reset()
                } label: {
                    Text("edit")
                }
            }
            
            if imageData == nil {
                Text("Photo")
                    .foregroundColor(.secondary)
            } else {
                #if os(macOS)
                Image(nsImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                #else
                Image(uiImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                #endif
            }
        }
        
    }
    
    private func categoryBrandSellerView() -> some View {
        VStack {
            categoryView()
            brandView()
            sellerView()
        }
    }
    
    private var itemKind: Kind? {
        let kinds = item.kind?.filter { $0 is Kind }.map { $0 as! Kind }
        return kinds?.first
    }
    
    private var itemKinds: [Kind] {
        item.kind?.filter { $0 is Kind }.map { $0 as! Kind } ?? [Kind]()
    }
    
    private var itemBrand: BrandDTO? {
        let brands = item.brand?
            .filter { $0 is Brand }
            .compactMap {
                if let brand = $0 as? Brand {
                    return BrandDTO(id: brand.uuid, name: brand.name, url: brand.url, created: brand.created, lastupd: brand.lastupd)
                } else {
                    return nil
                }
            }
        return brands?.first
    }
    
    private var itemSeller: SellerDTO? {
        let sellers = item.seller?
            .filter { $0 is Seller }
            .compactMap {
                if let seller = $0 as? Seller {
                    return SellerDTO(id: seller.uuid, name: seller.name, url: seller.url, created: seller.created, lastupd: seller.lastupd)
                } else {
                    return nil
                }
            }
        return sellers?.first
    }
    
    private func categoryView() -> some View {
        HStack {
            SectionTitleView(title: "CATEGORY")
            
            Spacer()
            
            if kind.isEmpty {
                VStack {
                    ForEach(itemKinds) {
                        Text($0.name ?? "")
                    }
                }
            } else {
                VStack {
                    ForEach(kind) {
                        Text($0.name ?? "")
                    }
                }
            }
            
            Button {
                kind = itemKinds
                presentChooseKindView = true
            } label: {
                Text("edit")
            }
        }
    }
    
    private func brandView() -> some View {
        HStack {
            SectionTitleView(title: "BRAND")
            
            Spacer()
            
            if brand == nil {
                Text(itemBrand?.name ?? "")
            } else {
                Text(brand!.name ?? "")
            }
            
            Button {
                brand = itemBrand
                presentChooseBrandView = true
            } label: {
                Text("edit")
            }
        }
    }
    
    private func sellerView() -> some View {
        HStack {
            SectionTitleView(title: "SELLER")
            
            Spacer()
            
            if seller == nil {
                Text(itemSeller?.name ?? "")
            } else {
                Text(seller!.name ?? "")
            }
            
            Button {
                seller = itemSeller
                presentChooseSellerView = true
            } label: {
                Text("edit")
            }
        }
    }
    
    private func quantityView() -> some View {
        HStack {
            SectionTitleView(title: "QUANTITY")
            
            Spacer()
            
            #if os(macOS)
            TextField("quantity", value: $quantity, formatter: quantityFormatter, prompt: Text("0"))
                .onSubmit({
                    isEdited = true
                })
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("quantity", value: $quantity, formatter: quantityFormatter, prompt: Text("0"))
                .focused($quantityIsFocused)
                .onChange(of: quantity) { newValue in
                    isEdited = newValue != Int(item.quantity)
                }
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                .keyboardType(.numberPad)
            
            if quantityIsFocused {
                Button {
                    quantityIsFocused = false
                } label: {
                    Text("Submit")
                }
            }
            #endif
        }
    }
    
    private func obtainedView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: "OBTAINED")
                
                Spacer()
                if isObtainedDateEdited {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else if let obtained = item.obtained {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
                
                Button(action: {
                    obtained = item.obtained ?? Date()
                    presentObtainedDatePickerView = true
                }, label: {
                    Text("edit")
                })
            }
        }
    }
    
    private func buyPriceView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "PRICE")
            
            #if os(macOS)
            TextField("buy price", value: $buyPrice, formatter: priceFormatter, prompt: Text("0.00"))
                .onSubmit({
                    isEdited = true
                })
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("buy price", value: $buyPrice, formatter: priceFormatter, prompt: Text("0.00"))
                .focused($buyPriceIsFocused)
                .onChange(of: buyPrice) { newValue in
                    isEdited = newValue != item.buyPrice
                }
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                .keyboardType(.decimalPad)
            #endif
        
            if buyPriceIsFocused {
                Button {
                    buyPriceIsFocused = false
                } label: {
                    Text("Submit")
                }
            } else {
                Text(buyCurrency)
                Button(action: {
                    presentChooseBuyCurrencyView = true
                }, label: {
                    Text("edit")
                })
            }
        }
    }
    
    private func disposedView() -> some View {
        VStack {
            HStack {
                SectionTitleView(title: "DISPOSED")

                Spacer()
                
                if isDisposedDateEdited {
                    Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else if let disposed = item.disposed {
                    Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
                Button(action: {
                    disposed = item.disposed ?? Date()
                    presentDisposedDatePickerView = true
                }, label: {
                    Text("edit")
                })
            }
        }
    }
    
    private func sellPriceView() -> some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: "PRICE")
            
            #if os(macOS)
            TextField("sell price", value: $sellPrice, formatter: priceFormatter, prompt: Text("0.00"))
                .onSubmit({
                    isEdited = true
                })
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("sell price", value: $sellPrice, formatter: priceFormatter, prompt: Text("0.00"))
                .focused($sellPriceIsFocused)
                .onChange(of: sellPrice) { newValue in
                    isEdited = newValue != item.sellPrice
                }
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                .keyboardType(.decimalPad)
            #endif
        
            if sellPriceIsFocused {
                Button {
                    sellPriceIsFocused = false
                } label: {
                    Text("Submit")
                }
            } else {
                Text(sellCurrency)
                Button(action: {
                    presentChooseSellCurrencyView = true
                }, label: {
                    Text("edit")
                })
            }
        }
    }
    
    private func noteView() -> some View {
        VStack(alignment: .leading) {
            SectionTitleView(title: "NOTE")
            
            TextField(item.note ?? "", text: $note)
                .onSubmit {
                    isEdited = true
                }
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func footer() -> some View {
        VStack {
            HStack {
                Spacer()
                
                SectionTitleView(title: "CREATED")

                Text("\(item.created ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
            
            HStack {
                Spacer()
                
                SectionTitleView(title: "UPDATED")
              
                Text("\(item.lastupd ?? Date(), formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
        }
    }
}

