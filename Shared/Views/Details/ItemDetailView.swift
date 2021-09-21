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
    @State var currency: String = "USD"
    @State var note: String = ""
    @State var obtained = Date()
    @State var disposed = Date()
    
    @State var presentPhotoView = false
    @State var presentChooseKindView = false
    @State var presentChooseBrandView = false
    @State var presentChooseSellerView = false
    @State var presentChooseCurrencyView = false
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
            }
            .sheet(isPresented: $presentChooseKindView, content: {
                ChooseKindView(kind: $kind)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onChange(of: kind) { _ in
                        isEdited = true
                    }
            })
            .sheet(isPresented: $presentChooseBrandView, content: {
                ChooseBrandView(brand: $brand)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onChange(of: brand) { _ in
                        isEdited = true
                    }
            })
            .sheet(isPresented: $presentChooseSellerView, content: {
                ChooseSellerView(seller: $seller)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onChange(of: seller) { _ in
                        isEdited = true
                    }
            })
            .sheet(isPresented: $presentChooseCurrencyView, content: {
                ChooseCurrencyView(currency: $currency)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentPhotoView, content: {
                EditPhotoView(originalImage: item.image, image: $imageData)
                    .environmentObject(viewModel)
                    .frame(width: geometry.size.width, height: geometry.size.height)
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
        currency = item.currency ?? "USD"
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
                                            currency: item.currency,
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
        VStack {
            Form {
                Section(header: photoHeader()) {
                    if imageData == nil {
                        Text("Photo")
                            .foregroundColor(.secondary)
                    } else {
                        #if os(macOS)
                        Image(nsImage: image!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        #else
                        Image(uiImage: image!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        #endif
                    }
                }
                
                Section(header: Text("name")) {
                    TextField(item.name ?? "", text: $name, onEditingChanged: { isEditing in
                        self.isEditing = isEditing
                    }, onCommit: {
                        isEditing = false
                        isEdited = true
                    })
                }
                
                Section(header: Text("category")) {
                    categoryView()
                }
                
                Section(header: Text("brand")) {
                    brandView()
                }
                
                Section(header: Text("seller")) {
                    sellerView()
                }
                
                Section(header: Text("quantity and prices")) {
                    quantityAndPricesView()
                }
                
                Section(header: Text("note")) {
                    Text(item.note ?? "")
                }
                
                Section(header: Text("dates")) {
                    datesView()
                }
                
                Section(header: Text("misc")) {
                    miscView()
                }
                
            }
            
        }
        .padding()
    }
    
    private func photoHeader() -> some View {
        HStack {
            Text("Photo")
            
            Button {
                kind = item.kind
                presentPhotoView = true
            } label: {
                Text("Edit")
            }
        }
    }
    
    private func categoryView() -> some View {
        HStack {
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
                Text("Edit")
            }
        }
    }
    
    private func brandView() -> some View {
        HStack {
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
                Text("Edit")
            }
        }
    }
    
    private func sellerView() -> some View {
        HStack {
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
                Text("Edit")
            }
        }
    }
    
    private func quantityAndPricesView() -> some View {
        VStack {
            HStack {
                Text("quantity")
                    .foregroundColor(.secondary)
                Spacer()
                TextField("\(item.quantity)", value: $quantity, formatter: quantityFormatter) { isEditing in
                    self.isEditing = isEditing
                } onCommit: {
                    isEditing = false
                    isEdited = true
                }
                .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("buy price")
                    .foregroundColor(.secondary)
                Spacer()
                TextField("\(item.buyPrice)", value: $buyPrice, formatter: priceFormatter) { isEditing in
                    self.isEditing = isEditing
                } onCommit: {
                    isEditing = false
                    isEdited = true
                }
                .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("sell price")
                    .foregroundColor(.secondary)
                Spacer()
                TextField("\(item.sellPrice)", value: $sellPrice, formatter: priceFormatter) { isEditing in
                    self.isEditing = isEditing
                } onCommit: {
                    isEditing = false
                    isEdited = true
                }
                .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("currency")
                    .foregroundColor(.secondary)
                Spacer()
                Text(item.currency ?? "")
                Button(action: {
                    presentChooseCurrencyView = true
                }, label: {
                    Text("Edit")
                })
            }
        }
    }
    
    private func datesView() -> some View {
        VStack {
            HStack {
                Text("obtained on")
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
                    Text("Edit")
                })
            }
            
            HStack {
                Text("disposed on")
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
                    Text("Edit")
                })
            }
        }
    }
    
    private func miscView() -> some View {
        VStack {
            HStack {
                Text("created on")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(item.created!, formatter: BelongingsViewModel.dateFormatter)")
            }
            
            HStack {
                Text("last updated  on")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(item.lastupd!, formatter: BelongingsViewModel.dateFormatter)")
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

