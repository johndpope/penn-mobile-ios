//
//  FrequentLocationsView.swift
//  PennMobile
//
//  Created by Dominic Holmes on 2/21/20.
//  Copyright © 2020 PennLabs. All rights reserved.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 13, *)
struct FrequentLocationsView: View {
    
    enum LengthOfTime: Int, CaseIterable {
        case week, month, semester
    }
    
    init(config: DiningStatisticsAPIResponse.CardData.FrequentLocationsCardData) {
        self.config = config
        _data = State(initialValue: config.data)
        _portions = State(initialValue: FrequentLocationsView.computeTotal(with: config.data, for: 0))
    }
    
    let config: DiningStatisticsAPIResponse.CardData.FrequentLocationsCardData
    @State private var data: [FrequentLocation]
    @State private var portions: [Double]
    // TODO: Expand the colors array to handle more than x venues
    @State private var colors: [Color] = [.orange, .yellow, .green, .blue, .pink, .purple, .red]
    @State private var lengthOfTime: Int = 0
    
    static func computeTotal(with data: [FrequentLocation], for lengthOfTime: Int) -> [Double] {
        let sum = data.reduce(0.0) { (result, freq) -> Double in
            result + spending(at: freq, in: lengthOfTime)
        }
        var values = [Double]()
        for freq in data {
            values.append(spending(at: freq, in: lengthOfTime) / sum)
        }
        return values
    }
    
    private static func spending(at location: FrequentLocation, in timeLength: Int) -> Double {
        spending(at: location, in: LengthOfTime(rawValue: timeLength) ?? .week)
    }
    
    private static func spending(at location: FrequentLocation, in timeLength: LengthOfTime) -> Double {
        switch timeLength {
        case .week: return location.week
        case .month: return location.month
        case .semester: return location.semester
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                    Text(config.headerTitle)
                }
                .font(Font.body.weight(.medium))
                .foregroundColor(.green)

                Text("\(config.headerBody) \(["week", "month", "semester"][lengthOfTime]).")
                .fontWeight(.medium)
                .lineLimit(nil)
                .frame(height: 44)
            }

            Divider()
                .padding([.top, .bottom])

            PortionView(portions: self.$portions, colors: self.$colors)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .frame(height: 20)
                .padding(.bottom)
                .opacity(0.6)

            VStack(alignment: .leading) {
                ForEach(self.data.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(self.colors[index])
                        Text(self.data[index].location)
                        Spacer()
                        Text("$\(FrequentLocationsView.spending(at: self.data[index], in: self.lengthOfTime))")
                    }
                }
            }

            Picker("Pick a time frame", selection: $lengthOfTime) {
                ForEach(0...2, id: \.self) { index in
                    Text(["This Week", "This Month", "This Semester"][index])
                }
            }
            .labelsHidden()
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top)
            .onReceive([self.lengthOfTime].publisher.first()) { (output) in
                withAnimation {
                    self.portions = FrequentLocationsView.computeTotal(with: self.data, for: self.lengthOfTime)
                }
            }
        }.padding()
    }
    
    struct PortionView: View {
        @Binding var portions: [Double]
        @Binding var colors: [Color]
        
        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(self.portions.indices, id: \.self) {
                        Rectangle()
                        .frame(width: geometry.size.width * CGFloat(self.portions[$0]))
                        .foregroundColor(self.colors[$0])
                    }
                }
            }
        }
    }
}

@available(iOS 13, *)
struct FrequentLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello")
        //FrequentLocationsView(config: , data: [])
    }
}
