//
//  AddBelongingView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State private var name = ""
    @State private var note = ""
    @State private var obtainedYear = 2020
    @State private var obtainedMonth = 1
    @State private var obtainedDay = 1
    @State private var buyPrice = ""
    @State private var quantity = ""
    
    @State private var presentChooseKindView = false
    @State private var presentManufacturerView = false
    @State private var presentSellerView = false
    
    @State private var kind: Kind?
    @State private var manufacturer: Manufacturer?
    @State private var seller: Seller?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                chooseName()
                
                chooseKind()
                
                chooseManufacturer()
                
                chooseSeller()
                
                chooseObtained()
                
                chooseBuyPrice()
                
                chooseQuantity()
                
                actions()
            }
            .sheet(isPresented: $presentChooseKindView, content: {
                ChooseKindView(kind: $kind)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentManufacturerView, content: {
                ChooseManufacturerView(manufacturer: $manufacturer)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .sheet(isPresented: $presentSellerView, content: {
                ChooseSellerView(seller: $seller)
                    .environment(\.managedObjectContext, viewContext)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            })
            .padding()
        }
    }
    
    private func chooseName() -> some View {
        HStack {
            Text("Name")
            
            TextField("Name", text: $name)
        }
    }
    
    private func chooseKind() -> some View {
        HStack {
            Text(kind == nil ? "item" : (kind!.name ?? "N/A"))
            
            Spacer()
            
            Button(action: {
                presentChooseKindView = true
            }, label: {
                Text("Choose an item")
            })
        }
    }
    
    private func chooseManufacturer() -> some View {
        HStack {
            Text(manufacturer == nil ? "manufacturer" : (manufacturer!.name ?? "N/A"))
            
            Spacer()
            
            Button(action: {
                presentManufacturerView = true
            }, label: {
                Text("Choose a manufacturer")
            })
        }
    }
    
    private func chooseSeller() -> some View {
        HStack {
            Text(seller == nil ? "seller" : (seller!.name ?? "N/A"))
            
            Spacer()
            
            Button(action: {
                presentSellerView = true
            }, label: {
                Text("Choose a seller")
            })
        }
    }
    
    private func chooseObtained() -> some View {
        HStack {
            Text("Obtained")
            
            Text("Year")
            
            TextField("yyyy", value: $obtainedYear, formatter: yearFormatter) { _ in
                
            } onCommit: {
                if obtainedYear < -9999 {
                    obtainedYear = -9999
                } else if obtainedYear > 9999 {
                    obtainedYear = 9999
                }
            }
            
            Text("Month")
            TextField("mm", value: $obtainedMonth, formatter: monthFormatter) { _ in
                
            } onCommit: {
                if obtainedMonth < 1{
                    obtainedMonth = 1
                } else if obtainedMonth > 12 {
                    obtainedMonth = 12
                }
            }
            
            Text("Day")
            TextField("dd", value: $obtainedDay, formatter: dayFormatter) { _ in
                
            } onCommit: {
                let calendar = Calendar(identifier: .iso8601)
                
                let dateComponents = DateComponents(calendar: calendar, year: obtainedYear, month: obtainedMonth, day: obtainedDay)
                
                if !dateComponents.isValidDate {
                    let validDateComponents = calendar.dateComponents([.year, .month, .day], from: dateComponents.date!)
                    
                    obtainedYear = validDateComponents.year!
                    obtainedMonth = validDateComponents.month!
                    obtainedDay = validDateComponents.day!
                }
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
    
    @State private var currency: String = "USD"
    
    private func chooseBuyPrice() -> some View {
        HStack {
            Text("Buy Price")
            
            TextField("0.0", text: $buyPrice)
            
            Picker("Currency", selection: $currency) {
                ForEach(NSLocale.commonISOCurrencyCodes, id: \.self) { currencyCode in
                    Text("\(currencyCode) (\(NSLocale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? ""))")
                }
            }
        }
    }
    
    private func chooseQuantity() -> some View {
        HStack {
            Text("Quantity")
            
            TextField("0", text: $quantity)
        }
    }
    
    private func actions() -> some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            },
            label: {
                Text("Cancel")
            })
            
            Button(action: {
                saveBelonging()
            },
            label: {
                Text("Save")
            })
        }
    }
    
    private var obtained: Date {
        let calendar = Calendar(identifier: .iso8601)
        
        let dateComponents = DateComponents(calendar: calendar, year: obtainedYear, month: obtainedMonth, day: obtainedDay)
        
        return dateComponents.date!
    }
    
    private func saveBelonging() -> Void {
        let created = Date()
        
        let newItem = Item(context: viewContext)
        newItem.created = created
        newItem.lastupd = created
        newItem.name = name
        newItem.note = note
        newItem.obtained = obtained
        newItem.buyPrice = Double(buyPrice) ?? -1.0
        newItem.currency = currency
        newItem.uuid = UUID()
        
        if kind != nil {
            kind!.addToItems(newItem)
        }
        
        if manufacturer != nil {
            manufacturer!.addToItems(newItem)
        }
        
        if seller != nil {
            seller!.addToItems(newItem)
        }
        
        let originalMergePolicy = viewContext.mergePolicy
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        viewContext.mergePolicy = originalMergePolicy
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddBelongingView_Previews: PreviewProvider {
    static var previews: some View {
        AddItemView()
    }
}
