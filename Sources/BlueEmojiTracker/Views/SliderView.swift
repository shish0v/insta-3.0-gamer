import SwiftUI

struct SliderView: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: format, value))
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct IntSliderView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            Slider(value: Binding(get: { Double(value) }, set: { value = Int($0) }), in: Double(range.lowerBound)...Double(range.upperBound))
            Text("\(value)")
                .frame(width: 40, alignment: .trailing)
        }
    }
}
