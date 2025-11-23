//
//  ExerciseInstructionsView.swift
//  Ascendr
//
//  View to display exercise instructions
//

import SwiftUI

struct ExerciseInstructionsView: View {
    let exercise: ExerciseItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise name
                    Text(exercise.name)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    // Category and Equipment
                    HStack(spacing: 16) {
                        Label(exercise.category.rawValue, systemImage: "tag.fill")
                        Label(exercise.equipment.rawValue, systemImage: "dumbbell.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Instructions
                    if let instructions = exercise.instructions {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal)
                            
                            Text(instructions)
                                .font(.body)
                                .lineSpacing(4)
                                .padding(.horizontal)
                        }
                    } else {
                        Text("No instructions available for this exercise.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // Muscle Groups
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Muscle Groups")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                Text(muscle.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(appSettings.accentColor.opacity(0.2))
                                    .foregroundColor(appSettings.accentColor)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Exercise Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

