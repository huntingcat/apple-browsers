//
//  ImportPasswordsViaSyncView.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import DesignResourcesKit
import Core
import DuckUI

struct ImportPasswordsViaSyncView: View {

    var viewModel: ImportPasswordsViaSyncViewModel

    var body: some View {

        ScrollView {
            VStack(spacing: 0) {
                ImportOverview(viewModel: viewModel)
                    .padding(.horizontal, 16)

                Divider()
                    .padding(.vertical, 32)

                StepByStepInstructions(viewModel: viewModel)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

        }
        .background(Rectangle()
            .foregroundColor(Color(designSystemColor: .background))
            .ignoresSafeArea())

    }

    private struct ImportOverview: View {

        var viewModel: ImportPasswordsViaSyncViewModel

        @State private var navigate = false

        var body: some View {
            Image(.syncDesktopNew128)

            Text(UserText.autofillImportPasswordsViaSyncTitle)
                .daxTitle2()
                .foregroundColor(Color(designSystemColor: .textPrimary))
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            Text(UserText.autofillImportPasswordsViaSyncSubtitle)
                .daxBodyRegular()
                .foregroundColor(Color(designSystemColor: .textSecondary))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button {
                viewModel.buttonPressed(.getBrowser)
                self.navigate = true
            } label: {
                Text(ImportPasswordsViaSyncViewModel.ButtonType.getBrowser.title)
                    .frame(width: viewModel.maxButtonWidth())
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            .padding(.top, 24)

            Button {
                viewModel.buttonPressed(.sync)
            } label: {
                Text(ImportPasswordsViaSyncViewModel.ButtonType.sync.title)
                    .frame(width: viewModel.maxButtonWidth())
            }
            .buttonStyle(SecondaryFillButtonStyle(fullWidth: false))
            .padding(.top, 8)

            NavigationLink(destination: DesktopDownloadView(viewModel: .init(platform: .desktop)), isActive: $navigate) {
                EmptyView()
            }

        }
    }

    private struct StepByStepInstructions: View {
        var viewModel: ImportPasswordsViaSyncViewModel

        var body: some View {

            VStack(alignment: .leading) {
                Text(UserText.autofillImportPasswordsViaSyncInstructionsTitle)
                    .daxHeadline()
                    .foregroundColor(Color(designSystemColor: .textPrimary))

                ForEach(ImportPasswordsViaSyncViewModel.InstructionStep.allCases, id: \.self) { step in

                    if step == .step2 || step == .step3 {
                        Instruction(step: step.rawValue, instructionText: attributedText(viewModel.attributedInstructionsForStep(step)))
                    } else {
                        Instruction(step: step.rawValue, instructionText: Text(viewModel.instructionsForStep(step)))
                    }
                }
            }

        }

        func attributedText(_ string: AttributedString) -> Text {
            return Text(string)
        }

    }

    struct Instruction: View {
        var step: Int
        var instructionText: Text

        var body: some View {

            HStack(alignment: .top, spacing: 16) {
                NumberBadge(number: step)
                instructionText
                    .daxBodyRegular()
                    .foregroundColor(Color(designSystemColor: .textSecondary))
                    .padding(.top, 6)
            }

        }
    }

}

struct NumberBadge: View {
    @Environment(\.colorScheme) var colorScheme

    var number: Int

    let lightBulletColor = Color(baseColor: .blue0).opacity(0.5)
    let darkBulletColor = Color(baseColor: .blue50).opacity(0.12)

    var body: some View {
        Text("\(number)")
            .daxHeadline()
            .background(
                Circle()
                    .fill(colorScheme == .dark ? darkBulletColor : lightBulletColor)
                    .frame(width: 24, height: 24)
            )
            .foregroundColor(Color(designSystemColor: .accent))
            .fixedSize()
            .padding(10)
    }
}

struct ImportPasswordsViaSyncView_Previews: PreviewProvider {
    static var previews: some View {
        ImportPasswordsViaSyncView(viewModel: ImportPasswordsViaSyncViewModel()).preferredColorScheme(.light)
        ImportPasswordsViaSyncView(viewModel: ImportPasswordsViaSyncViewModel()).preferredColorScheme(.dark)
    }
}
