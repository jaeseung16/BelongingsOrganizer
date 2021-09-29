//
//  AddBelongingView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AddItemViewModel
    
    @State private var name = ""
    @State private var note = ""
    @State private var obtainedDate = Date()
    @State private var buyPrice = ""
    @State private var quantity = ""
    @State private var currency: String = "USD"
    
    @State private var presentChooseKindView = false
    @State private var presentBrandView = false
    @State private var presentSellerView = false
    @State private var presentCurrencyView = false
    @State private var presentPhotoView = false
    
    @State private var kind: Kind?
    @State private var brand: Brand?
    @State private var seller: Seller?
    
    //@State private var image: Data?
    private var image: Data? {
        viewModel.imageData
    }
    
    @State private var classificationResult = "classificationResult"
    
    var geometry: GeometryProxy
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Add an item")
                    .font(.title3)
                
                Divider()
                
                inputFormView()
                
                Divider()
                
                actions()
            }
            .sheet(isPresented: $presentChooseKindView, content: {
                ChooseKindView(kind: $kind)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentBrandView, content: {
                ChooseBrandView(brand: $brand)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentSellerView, content: {
                ChooseSellerView(seller: $seller)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentCurrencyView, content: {
                ChooseCurrencyView(currency: $currency)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentPhotoView, content: {
                #if os(macOS)
                MacAddPhotoView()
                    .environmentObject(viewModel)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                #else
                AddPhotoView()
                    .environmentObject(viewModel)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                #endif
            })
        }
    }
    
    private func inputFormView() -> some View {
        VStack {
            inputNameView()
            
            inputPhotoView()
            
            inputKindView()
            
            inputBrandView()
            
            inputSellerView()
            
            inputObtainedView()
            
            inputBuyPriceView()
            
            inputQuantityView()
        }
    }
    
    private func inputNameView() -> some View {
        VStack {
            HStack {
                Text("NAME")
                    .font(.caption)
                Spacer()
            }
            
            TextField("name", text: $name)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func inputPhotoView() -> some View {
        VStack {
            HStack {
                Text("PHOTO")
                    .font(.caption)
                Spacer()
                Button(action: {
                    presentPhotoView = true
                }, label: {
                    Label("select", systemImage: "photo")
                })
            }
            
            if image == nil {
                Label("photo", systemImage: "photo.on.rectangle")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            } else {
                #if os(macOS)
                Image(nsImage: NSImage(data: image!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                #else
                Image(uiImage: UIImage(data: image!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                #endif
            }
        }
        
    }
    
    private func inputKindView() -> some View {
        VStack {
            HStack {
                Text("CATEGORY")
                    .font(.caption)
                Spacer()
                Button(action: {
                    presentChooseKindView = true
                }, label: {
                    Label("select", systemImage: "filemenu.and.selection")
                })
            }
            
            if kind == nil {
                Text("category")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            } else {
                Text(kind!.name ?? "N/A")
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func inputBrandView() -> some View {
        VStack {
            HStack {
                Text("BRAND")
                    .font(.caption)
                Spacer()
                Button(action: {
                    presentBrandView = true
                }, label: {
                    Label("select", systemImage: "filemenu.and.selection")
                })
            }
            
            if brand == nil {
                Text("brand")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            } else {
                Text(brand!.name ?? "N/A")
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            }
        }
    }
    
    private func inputSellerView() -> some View {
        VStack {
            HStack {
                Text("SELLER")
                    .font(.caption)
                
                Spacer()
                
                Button(action: {
                    presentSellerView = true
                }, label: {
                    Label("select", systemImage: "filemenu.and.selection")
                })
            }
            
            if seller == nil {
                Text("seller")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            } else {
                Text(seller!.name ?? "N/A")
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            }
        }
    }
    
    private func inputObtainedView() -> some View {
        HStack {
            Text("OBTAINED")
                .font(.caption)
            
            Spacer()
            
            DatePicker("", selection: $obtainedDate, displayedComponents: [.date])
        }
    }
    
    private func inputBuyPriceView() -> some View {
        VStack {
            HStack {
                Text("CURRENCY")
                    .font(.caption)
                
                Spacer()
                
                Text(currency)
                    .frame(maxWidth: 50)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                Button(action: {
                    presentCurrencyView = true
                }, label: {
                    Label("select", systemImage: "filemenu.and.selection")
                })
                
            }
            
            HStack {
                Text("PRICE")
                    .font(.caption)
                
                Spacer()
                
                #if os(macOS)
                TextField("0.00", text: $buyPrice)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                #else
                TextField("0.00", text: $buyPrice)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                    .keyboardType(.decimalPad)
                #endif
            }
        }
    }
    
    private func inputQuantityView() -> some View {
        HStack {
            Text("QUANTITY")
                .font(.caption)
            
            Spacer()
            
            #if os(macOS)
            TextField("0", text: $quantity)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            #else
            TextField("0", text: $quantity)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                .keyboardType(.numberPad)
            #endif
        }
    }
    
    private func actions() -> some View {
        HStack {
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            },
            label: {
                Text("Cancel")
            })
            
            Spacer()
            
            Button(action: {
                saveBelonging()
            },
            label: {
                Text("Save")
            })
            
            Spacer()
        }
    }
    
    private var obtained: Date {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.startOfDay(for: obtainedDate)
    }
        
    private func saveBelonging() -> Void {
        viewModel.saveBelonging(name: name,
                                kind: kind,
                                brand: brand,
                                seller: seller,
                                note: note,
                                obtained: obtained,
                                buyPrice: Double(buyPrice),
                                quantity: Int64(quantity),
                                buyCurrency: currency)
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddBelongingView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            AddItemView(geometry: geometry)
        }
    }
}
