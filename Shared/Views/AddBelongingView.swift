//
//  AddBelongingView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct AddBelongingView: View { @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var note = ""
    @State private var obtainedYear = 2020
    @State private var obtainedMonth = 1
    @State private var obtainedDay = 1
    @State private var buyPrice = ""
    @State private var quantity = ""
    
    @State private var presentChooseItemView = false
    
    @State private var item: Item?
    
    var body: some View {
        VStack {
            chooseName()
            
            chooseItem()
            
            chooseObtained()
            
            Text("Buy Price")
            
            TextField("0.0", text: $buyPrice)
            
            Text("Quantity")
            
            TextField("0", text: $quantity)
            
            actions()
        }
        .sheet(isPresented: $presentChooseItemView, content: {
            ChooseItemView(item: $item)
                .environment(\.managedObjectContext, viewContext)
        })
        .padding()
    }
    
    private func chooseName() -> some View {
        VStack {
            Text("Name")
            
            TextField("Name", text: $name)
        }
    }
    
    private func chooseItem() -> some View {
        VStack {
            Text("Item")
            
            HStack {
                Text(item == nil ? "N/A" : (item!.name ?? "N/A"))

                Spacer()
                
                Button(action: {
                    presentChooseItemView = true
                }, label: {
                    Text("Choose an item")
                })
            }
        }
    }
    
    private func chooseObtained() -> some View {
        VStack {
            Text("Obtained")
        
            HStack {
                Text("Year")
               
                TextField("Year", value: $obtainedYear, formatter: yearFormatter) { _ in
                    
                } onCommit: {
                    if obtainedYear < -9999 {
                        obtainedYear = -9999
                    } else if obtainedYear > 9999 {
                        obtainedYear = 9999
                    }
                }
                
                Text("Month")
                TextField("Month", value: $obtainedMonth, formatter: monthFormatter) { _ in
                    
                } onCommit: {
                    if obtainedMonth < 1{
                        obtainedMonth = 1
                    } else if obtainedMonth > 12 {
                        obtainedMonth = 12
                    }
                }
                
                Text("Day")
                TextField("Day", value: $obtainedDay, formatter: dayFormatter) { _ in
                    
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
        let newBelonging = Belongings(context: viewContext)
        newBelonging.created = Date()
        newBelonging.lastupd = newBelonging.created
        newBelonging.name = name
        newBelonging.note = note
        newBelonging.obtained = obtained
        newBelonging.buyPrice = Double(buyPrice) ?? -1.0
        
        if item != nil {
            item!.addToBelongings(newBelonging)
        }

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct AddBelongingView_Previews: PreviewProvider {
    static var previews: some View {
        AddBelongingView()
    }
}
