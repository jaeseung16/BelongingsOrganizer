//
//  ItemDetailView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var item: Item
    @State private var kind: Kind?
    @State private var brand: Brand?
    @State private var seller: Seller?
    
    @State private var isEditing = false
    @State private var isEdited = false
    
    @State var imageData: Data?
    @State var name = ""
    @State var quantity: Int64 = 0
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                itemInfo()
                
                Divider()
                
                footer()
            }
            .padding()
            .sheet(isPresented: $presentChooseKindView, content: {
                #if os(macOS)
                ChooseKindView(kind: $kind)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: kind) { _ in
                        isEdited = true
                    }
                #else
                ChooseKindView(kind: $kind)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
                    .onChange(of: kind) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseBrandView, content: {
                #if os(macOS)
                ChooseBrandView(brand: $brand)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: brand) { _ in
                        isEdited = true
                    }
                #else
                ChooseBrandView(brand: $brand)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
                    .onChange(of: brand) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseSellerView, content: {
                #if os(macOS)
                ChooseSellerView(seller: $seller)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                    .onChange(of: seller) { _ in
                        isEdited = true
                    }
                #else
                ChooseSellerView(seller: $seller)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
                    .onChange(of: seller) { _ in
                        isEdited = true
                    }
                #endif
            })
            .sheet(isPresented: $presentChooseBuyCurrencyView, content: {
                #if os(macOS)
                ChooseCurrencyView(currency: $buyCurrency)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.2 * geometry.size.height)
                #else
                ChooseCurrencyView(currency: $buyCurrency)
                #endif
            })
            .sheet(isPresented: $presentChooseSellCurrencyView, content: {
                #if os(macOS)
                ChooseCurrencyView(currency: $sellCurrency)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.2 * geometry.size.height)
                #else
                ChooseCurrencyView(currency: $sellCurrency)
                #endif
            })
            .sheet(isPresented: $presentPhotoView, content: {
                #if os(macOS)
                EditPhotoView(originalImage: item.image, image: $imageData)
                    .frame(minWidth: 0.5 * geometry.size.width, minHeight: 0.5 * geometry.size.height)
                #else
                EditPhotoView(originalImage: item.image, image: $imageData)
                #endif
            })
            .sheet(isPresented: $presentObtainedDatePickerView, content: {
                EditDateView(date: $obtained, originalDate: item.obtained, isEdited: $isObtainedDateEdited)
            })
            .sheet(isPresented: $presentDisposedDatePickerView, content: {
                EditDateView(date: $disposed, originalDate: item.disposed, isEdited: $isDisposedDateEdited)
            })
        }
    }
    
    private func reset() -> Void {
        imageData = item.image
        name = item.name ?? ""
        quantity = item.quantity
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
                                            note: item.note,
                                            quantity: quantity,
                                            buyPrice: item.buyPrice,
                                            sellPrice: item.sellPrice,
                                            buyCurrency: item.buyCurrency,
                                            sellCurrency: item.sellCurrency,
                                            obtained: isObtainedDateEdited ? obtained : item.obtained,
                                            disposed: isDisposedDateEdited ? disposed : item.disposed,
                                            image: imageData ?? item.image)
                
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited && imageData == nil)
            
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
            Text("NAME")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            TextField(item.name ?? "", text: $name, onEditingChanged: { isEditing in
                self.isEditing = isEditing
            }, onCommit: {
                isEditing = false
                isEdited = true
            })
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func photoView() -> some View {
        VStack {
            HStack {
                Text("PHOTO")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
            Text("CATEGORY")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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
            Text("BRAND")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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
            Text("SELLER")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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
            Text("QUANTITY")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            
            #if os(macOS)
            TextField("\(item.quantity)", value: $quantity, formatter: quantityFormatter) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 80)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("\(item.quantity)", value: $quantity, formatter: quantityFormatter) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 80)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .keyboardType(.numberPad)
            #endif
        }
    }
    
    private func obtainedView() -> some View {
        VStack {
            HStack {
                Text("OBTAINED")
                    .font(.callout)
                    .foregroundColor(.secondary)
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
            Text("PRICE")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            
            #if os(macOS)
            TextField("\(item.buyPrice)", value: $buyPrice, formatter: priceFormatter) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 120)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("\(item.buyPrice)", value: $buyPrice, formatter: priceFormatter) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 120)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .keyboardType(.decimalPad)
            #endif
        
            Spacer()
            
            Text(item.buyCurrency ?? "")
            Button(action: {
                presentChooseBuyCurrencyView = true
            }, label: {
                Text("edit")
            })
        }
    }
    
    private func disposedView() -> some View {
        VStack {
            HStack {
                Text("DISPOSED")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            Text("PRICE")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            
            #if os(macOS)
            TextField("\(item.sellPrice)", value: $sellPrice, formatter: priceFormatter) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 120)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("\(item.sellPrice)", value: $sellPrice, formatter: priceFormatter) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                isEditing = false
                isEdited = true
            }
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 120)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .keyboardType(.decimalPad)
            #endif
        
            Spacer()
            
            Text(item.sellCurrency ?? "USD")
            Button(action: {
                presentChooseSellCurrencyView = true
            }, label: {
                Text("edit")
            })
        }
    }
    
    private func noteView() -> some View {
        HStack {
            Text("NOTE")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(item.note ?? "")
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func footer() -> some View {
        VStack {
            HStack {
                Text("created")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(item.created!, formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
            
            HStack {
                Text("last updated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(item.lastupd!, formatter: BelongingsViewModel.dateFormatter)")
                    .font(.callout)
            }
        }
    }
    
    private var yearFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.maximumIntegerDigits = 4
        return numberFormatter
    }
    
    private var monthFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.maximumIntegerDigits = 2
        return numberFormatter
    }
    
    private var dayFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.maximumIntegerDigits = 2
        return numberFormatter
    }
    
}

