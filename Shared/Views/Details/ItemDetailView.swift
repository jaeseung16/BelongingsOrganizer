//
//  ItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var item: Item
    @State private var kind: Kind?
    @State private var brand: Brand?
    @State private var seller: Seller?
    
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
            .navigationTitle(item.name ?? "N/A")
            .padding()
            .sheet(isPresented: $presentChooseKindView, content: {
                #if os(macOS)
                ChooseKindView(kind: $kind)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: kind) { _ in
                        isEdited = true
                    }
                #else
                ChooseKindView(kind: $kind)
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
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.5 * geometry.size.height)
                    .onChange(of: imageData) { _ in
                        isEdited = true
                    }
                #else
                EditPhotoView(originalImage: item.image, image: $imageData)
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
        
        kind = nil
        brand = nil
        seller = nil
        
        isEditing = false
        isEdited = false
        isObtainedDateEdited = false
        isDisposedDateEdited = false
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                reset()
            } label: {
                Text("Reset")
            }
            
            Spacer()
            
            Button {
                if kind != nil && kind != item.kind {
                    if let originalKind = item.kind {
                        originalKind.removeFromItems(item)
                    }
                    kind?.addToItems(item)
                }
                
                if brand != nil && brand != item.brand {
                    if let originalBrand = item.brand {
                        originalBrand.removeFromItems(item)
                    }
                    brand?.addToItems(item)
                }
                
                if seller != nil && seller != item.seller {
                    if let originalSeller = item.seller {
                        originalSeller.removeFromItems(item)
                    }
                    seller?.addToItems(item)
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
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
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
                    kind = item.kind
                    presentPhotoView = true
                    AddItemViewModel.shared.reset()
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
    
    private func categoryView() -> some View {
        HStack {
            SectionTitleView(title: "CATEGORY")
            
            Spacer()
            
            if kind == nil {
                Text(item.kind?.name ?? "")
            } else {
                Text(kind!.name ?? "")
            }
            
            Button {
                kind = item.kind
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
                Text(item.brand?.name ?? "")
            } else {
                Text(brand!.name ?? "")
            }
            
            Button {
                brand = item.brand
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
                Text(item.seller?.name ?? "")
            } else {
                Text(seller!.name ?? "")
            }
            
            Button {
                seller = item.seller
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

