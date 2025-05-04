//
//  AuthView.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - ViewModel
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userRole: String? = nil
    @Published var bondedUserId: String? = nil
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var pendingBondRequests: [BondRequest] = []
    @Published var receivedBondRequests: [BondRequest] = []
    @Published var pairedUser: UserProfile? = nil
    @Published var showRoleSelection: Bool = false
    @Published var showBondRequests: Bool = false
    @Published var errorMessage: String? = nil

    struct BondRequest: Identifiable {
        let id: String
        let senderId: String
        let senderRole: String
        let receiverEmail: String
        let status: String
        let createdAt: Timestamp?
    }
    struct UserProfile {
        let uid: String
        let email: String
        let displayName: String
        let role: String
    }

    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
        if let user = Auth.auth().currentUser {
            self.email = user.email ?? ""
            fetchUserProfile(uid: user.uid)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else if let user = result?.user {
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(user.uid)
                    userRef.setData([
                        "email": email,
                        "displayName": "",
                        "role": NSNull(),
                        "bondedUserId": NSNull(),
                        "createdAt": FieldValue.serverTimestamp(),
                        "lastLoginAt": FieldValue.serverTimestamp()
                    ], merge: true)
                    self?.isLoggedIn = true
                    self?.email = email
                    self?.showRoleSelection = true
                    completion(nil)
                }
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else if let user = result?.user {
                    self?.isLoggedIn = true
                    self?.email = email
                    self?.fetchUserProfile(uid: user.uid)
                    completion(nil)
                }
            }
        }
    }

    func fetchUserProfile(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] doc, _ in
            if let data = doc?.data() {
                self?.userRole = data["role"] as? String
                self?.bondedUserId = data["bondedUserId"] as? String
                self?.displayName = data["displayName"] as? String ?? ""
                if let bondedId = self?.bondedUserId, !bondedId.isEmpty {
                    self?.fetchPairedUser(uid: bondedId)
                }
            }
        }
    }

    func updateUserRole(role: String, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion("Not logged in"); return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "role": role
        ], merge: true) { err in
            DispatchQueue.main.async {
                if let err = err {
                    completion(err.localizedDescription)
                } else {
                    self.userRole = role
                    completion(nil)
                }
            }
        }
    }

    func sendBondRequest(receiverEmail: String, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, let role = userRole else { completion("Not logged in or role not set"); return }
        let db = Firestore.firestore()
        db.collection("bondRequests").addDocument(data: [
            "senderId": uid,
            "senderRole": role,
            "receiverEmail": receiverEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]) { err in
            DispatchQueue.main.async {
                if let err = err {
                    completion(err.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func fetchBondRequests() {
        guard let uid = Auth.auth().currentUser?.uid, let email = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        // Sent requests
        db.collection("bondRequests").whereField("senderId", isEqualTo: uid).getDocuments { [weak self] snap, _ in
            self?.pendingBondRequests = snap?.documents.compactMap { doc in
                let d = doc.data()
                return BondRequest(
                    id: doc.documentID,
                    senderId: d["senderId"] as? String ?? "",
                    senderRole: d["senderRole"] as? String ?? "",
                    receiverEmail: d["receiverEmail"] as? String ?? "",
                    status: d["status"] as? String ?? "",
                    createdAt: d["createdAt"] as? Timestamp
                )
            } ?? []
        }
        // Received requests
        db.collection("bondRequests").whereField("receiverEmail", isEqualTo: email).getDocuments { [weak self] snap, _ in
            self?.receivedBondRequests = snap?.documents.compactMap { doc in
                let d = doc.data()
                return BondRequest(
                    id: doc.documentID,
                    senderId: d["senderId"] as? String ?? "",
                    senderRole: d["senderRole"] as? String ?? "",
                    receiverEmail: d["receiverEmail"] as? String ?? "",
                    status: d["status"] as? String ?? "",
                    createdAt: d["createdAt"] as? Timestamp
                )
            } ?? []
        }
    }

    func acceptBondRequest(request: BondRequest, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion("Not logged in"); return }
        let db = Firestore.firestore()
        // Find sender's userId by email
        db.collection("users").whereField("email", isEqualTo: request.receiverEmail).getDocuments { snap, _ in
            guard let receiverDoc = snap?.documents.first else { completion("User not found"); return }
            let receiverId = receiverDoc.documentID
            // Update bond request status
            db.collection("bondRequests").document(request.id).updateData(["status": "accepted"]) { err in
                if let err = err { completion(err.localizedDescription); return }
                // Update both users
                db.collection("users").document(request.senderId).updateData(["bondedUserId": receiverId])
                db.collection("users").document(receiverId).updateData(["bondedUserId": request.senderId])
                completion(nil)
            }
        }
    }

    func fetchPairedUser(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] doc, _ in
            if let d = doc?.data() {
                self?.pairedUser = UserProfile(
                    uid: uid,
                    email: d["email"] as? String ?? "",
                    displayName: d["displayName"] as? String ?? "",
                    role: d["role"] as? String ?? ""
                )
            }
        }
    }

    func logInteraction(masterId: String, puppyId: String, type: String) {
        let db = Firestore.firestore()
        db.collection("interactions").addDocument(data: [
            "masterId": masterId,
            "puppyId": puppyId,
            "timestamp": FieldValue.serverTimestamp(),
            "type": type,
            "responseType": NSNull(),
            "responseTimestamp": NSNull(),
            "responseTimeSeconds": NSNull()
        ])
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
        self.userRole = nil
        self.bondedUserId = nil
        self.displayName = ""
        self.email = ""
        self.pairedUser = nil
        self.pendingBondRequests = []
        self.receivedBondRequests = []
    }
}

// MARK: - MainView
struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSettings = false
    @State private var showBondRequestSheet = false
    @State private var showBondRequestsSheet = false
    @State private var bondRequestEmail = ""

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Text("欢迎来到 PuppyBell!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                if let paired = authVM.pairedUser {
                    VStack(spacing: 8) {
                        Text("已绑定用户：")
                            .foregroundColor(.white)
                        Text("\(paired.displayName.isEmpty ? paired.email : paired.displayName) (") + Text(paired.role == "master" ? "主人" : "小狗") + Text(")")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                } else {
                    Button(action: { showBondRequestSheet = true }) {
                        Text("发送绑定请求")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal, 40)
                    Button(action: { showBondRequestsSheet = true }) {
                        Text("查看收到的绑定请求")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .underline()
                    }
                }
                Button(action: { showSettings = true }) {
                    Text("账户设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 40)
            }
            .sheet(isPresented: $showSettings) {
                AccountSettingsView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showBondRequestSheet) {
                BondRequestSheet(viewModel: authVM, isPresented: $showBondRequestSheet)
            }
            .sheet(isPresented: $showBondRequestsSheet) {
                BondRequestsListSheet(viewModel: authVM, isPresented: $showBondRequestsSheet)
            }
        }
    }
}

// MARK: - AccountSettingsView
struct AccountSettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Text("账户设置")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                Button(action: {
                    authVM.signOut()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("退出登录")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 40)
                Spacer()
            }
            .padding(32)
            .background(Color.white.opacity(0.1))
            .cornerRadius(24)
            .shadow(radius: 10)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - AuthView
struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = "richard@james.cn"
    @State private var password = "901901"
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showBondRequestSheet = false
    @State private var bondRequestEmail = ""
    @State private var showBondRequestsSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 28) {
                    Text(isSignUp ? "Sign Up" : "Login")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                        .padding(.bottom, 10)

                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal, 8)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Button(action: handleAuth) {
                            Text(isSignUp ? "Sign Up" : "Login")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .padding(.horizontal, 8)
                    }

                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .underline()
                    }
                }
                .padding(32)
                .background(Color.white.opacity(0.1))
                .cornerRadius(24)
                .shadow(radius: 10)
                .padding(.horizontal, 16)
                .background(
                    NavigationLink(
                        destination: RoleSelectionScreen(viewModel: viewModel),
                        isActive: $viewModel.showRoleSelection,
                        label: { EmptyView() }
                    )
                    .hidden()
                )
            }
        }
    }

    private func handleAuth() {
        errorMessage = nil
        isLoading = true
        if isSignUp {
            viewModel.signUp(email: email, password: password) { error in
                isLoading = false
                if let error = error {
                    errorMessage = error
                }
            }
        } else {
            viewModel.login(email: email, password: password) { error in
                isLoading = false
                if let error = error {
                    errorMessage = error
                }
            }
        }
    }
}

// MARK: - RoleSelectionScreen
struct RoleSelectionScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRole: String? = nil

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 28) {
                Text("选择你的身份")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                HStack(spacing: 24) {
                    Button(action: { selectRole("master") }) {
                        Text("主人")
                            .font(.headline)
                            .frame(width: 120, height: 50)
                            .background(selectedRole == "master" ? Color.blue : Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(radius: 4)
                    }
                    Button(action: { selectRole("puppy") }) {
                        Text("小狗")
                            .font(.headline)
                            .frame(width: 120, height: 50)
                            .background(selectedRole == "puppy" ? Color.pink : Color.pink.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(radius: 4)
                    }
                }
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .padding(32)
            .background(Color.white.opacity(0.1))
            .cornerRadius(24)
            .shadow(radius: 10)
            .padding(.horizontal, 16)
        }
    }

    private func selectRole(_ role: String) {
        isLoading = true
        errorMessage = nil
        viewModel.updateUserRole(role: role) { error in
            isLoading = false
            if let error = error {
                errorMessage = error
            } else {
                selectedRole = role
            }
        }
    }
}

// MARK: - BondRequestSheet
struct BondRequestSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var email: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @State private var sent = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("发送绑定请求")
                    .font(.title2)
                    .bold()
                TextField("对方邮箱", text: $email)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                if sent {
                    Text("请求已发送！")
                        .foregroundColor(.green)
                }
                Button(action: sendRequest) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("发送")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading)
                Spacer()
            }
            .padding()
            .navigationBarTitle("绑定请求", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") { isPresented = false })
        }
    }

    private func sendRequest() {
        errorMessage = nil
        isLoading = true
        viewModel.sendBondRequest(receiverEmail: email) { error in
            isLoading = false
            if let error = error {
                errorMessage = error
            } else {
                sent = true
            }
        }
    }
}

// MARK: - BondRequestsListSheet
struct BondRequestsListSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("收到的绑定请求")
                    .font(.title2)
                    .bold()
                if isLoading {
                    ProgressView()
                } else if viewModel.receivedBondRequests.isEmpty {
                    Text("暂无请求")
                        .foregroundColor(.gray)
                } else {
                    List(viewModel.receivedBondRequests) { req in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("来自: \(req.senderRole == "master" ? "主人" : "小狗")")
                            Text("邮箱: \(req.senderId)")
                            Text("状态: \(req.status)")
                            if req.status == "pending" {
                                Button("接受") {
                                    acceptRequest(req)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("绑定请求", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") { isPresented = false })
            .onAppear {
                isLoading = true
                viewModel.fetchBondRequests()
                isLoading = false
            }
        }
    }

    private func acceptRequest(_ req: AuthViewModel.BondRequest) {
        isLoading = true
        errorMessage = nil
        viewModel.acceptBondRequest(request: req) { error in
            isLoading = false
            if let error = error {
                errorMessage = error
            } else {
                isPresented = false
            }
        }
    }
}
