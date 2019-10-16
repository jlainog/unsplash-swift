//
//  LoginCombineExample.swift
//  unsplash-swift-example
//
//  Created by jaime Laino Guerra on 9/30/19.
//  Copyright © 2019 jaime Laino Guerra. All rights reserved.
//

import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
  private var cancellable = Set<AnyCancellable>()
  
  @Published var mail: String = ""
  @Published var password: String = ""
  @Published var passwordAgain: String = ""
  
  var mailMessage: String = ""
  var passwordMessage: String = ""
  var enabledContinue: Bool = false
  
  init() {
    isLoginInfoValidPublisher
      .receive(on: RunLoop.main)
      .assign(to: \.enabledContinue, on: self)
      .store(in: &cancellable)
    
    isValidUserNamePublisher
      .receive(on: RunLoop.main)
      .map { $0 ? "" : "Your mail should be longer than 3 characters" }
      .assign(to: \.mailMessage, on: self)
      .store(in: &cancellable)
    
    isPasswordValidPublisher
      .receive(on: RunLoop.main)
      .map { $0 ? "" : "Validate your passwords are equal and contains at leats 6 characters" }
      .assign(to: \.passwordMessage, on: self)
      .store(in: &cancellable)
  }
}
private extension LoginViewModel {
  var isValidUserNamePublisher: AnyPublisher<Bool, Never> {
    $mail
//      .debounce(for: 0.5, scheduler: RunLoop.main)
      .removeDuplicates()
      .map { $0.count >= 2 }
      .eraseToAnyPublisher()
  }
  
  var isPasswordNotEmptyPublisher: AnyPublisher<Bool, Never> {
    $password
//      .debounce(for: 0.5, scheduler: RunLoop.main)
      .removeDuplicates()
      .map { !$0.isEmpty }
      .print()
      .eraseToAnyPublisher()
  }
  
  var arePasswordEqualPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest($password, $passwordAgain)
//      .debounce(for: 0.2, scheduler: RunLoop.main)
      .map { $0 == $1 }
      .eraseToAnyPublisher()
  }
  
  var isPasswordStrongPublisher: AnyPublisher<Bool, Never> {
    $password
//      .debounce(for: 0.2, scheduler: RunLoop.main)
      .removeDuplicates()
      .map { $0.count } // use what ever algorithm to check strenght
      .map { $0 >= 5 }
      .eraseToAnyPublisher()
  }
  
  var isPasswordValidPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest3(isPasswordNotEmptyPublisher,
                              arePasswordEqualPublisher,
                              isPasswordStrongPublisher)
      .map { $0 && $1 && $2 }
      .eraseToAnyPublisher()
  }
  
  var isLoginInfoValidPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest(isValidUserNamePublisher,
                             isPasswordValidPublisher)
      .map { $0 && $1 }
      .eraseToAnyPublisher()
  }
}

struct LoginFormView: View {
  @ObservedObject private var viewModel: LoginViewModel = .init()
  
  var body: some View {
    Form {
      Section(footer: Text(viewModel.mailMessage).foregroundColor(.red)) {
        TextField("Email", text: $viewModel.mail)
          .autocapitalization(.none)
      }
      Section(footer: Text(viewModel.passwordMessage).foregroundColor(.red)) {
        SecureField("Password", text: $viewModel.password)
        SecureField("Password again", text: $viewModel.passwordAgain)
      }
      Section {
        Button(action: {},
               label: { Text("Continue") })
          .disabled(!viewModel.enabledContinue)
      }
    }
  }
}

struct LoginFormView_Previews: PreviewProvider {
  static var previews: some View {
    LoginFormView()
      .environment(\.colorScheme, .dark)
  }
}
