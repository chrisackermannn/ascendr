//
//  AscendrLogo.swift
//  Ascendr
//
//  Bold Ascendr logo component
//

import SwiftUI

struct AscendrLogo: View {
    var size: CGFloat = 28
    
    var body: some View {
        Text("Ascendr")
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundColor(.black)
    }
}

#Preview {
    VStack(spacing: 20) {
        AscendrLogo()
        AscendrLogo(size: 32)
        AscendrLogo(size: 24)
    }
    .padding()
}

