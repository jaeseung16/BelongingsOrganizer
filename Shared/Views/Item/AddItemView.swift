//
//  AddBelongingView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State private var name = ""
    @State private var note = ""
    @State private var obtainedDate = Date()
    @State private var buyPrice = ""
    @State private var quantity = ""
    
    @AppStorage("BelongingsOrganizer.currency")
    private var currency: String = "USD"
    
    @State private var kind = [Kind]()
    @State private var brand: Brand?
    @State private var seller: Seller?
    
    //@State private var image: Data?
    @State private var image: Data?
    
    @State private var classificationResult = "classificationResult"
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Add an item")
                    .font(.title3)
                
                Divider()
                
                inputFormView(in: geometry)
                
                Divider()
                
                actions
            }
            .padding()
        }
    }
    
    private func inputFormView(in geometry: GeometryProxy) -> some View {
        VStack {
            InputNameView(name: $name)
            
            InputPhotoView(image: $image, geometry: geometry)
            
            InputKindView(kind: $kind, geometry: geometry)
            
            InputBrandView(brand: $brand, geometry: geometry)
            
            InputSellerView(seller: $seller, geometry: geometry)
            
            InputObtainedView(obtainedDate: $obtainedDate, geometry: geometry)
            
            InputBuyCurrencyView(currency: $currency, geometry: geometry)
            
            InputBuyPriceView(buyPrice: $buyPrice, geometry: geometry)
            
            InputQuantityView(quantity: $quantity, geometry: geometry)
        }
    }
    
    private var actions: some View {
        HStack {
            Spacer()
            
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Cancel")
            }
            
            Spacer()
            
            Button {
                saveBelonging()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            
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
                                buyCurrency: currency,
                                image: image)
        
        dismiss.callAsFunction()
    }
}
