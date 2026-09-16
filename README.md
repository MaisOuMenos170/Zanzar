# Zanzar

"""swift
/ZanzarProject (parent folder)
	/ZanzarProject (app folder)
		/App (contains ContentView and main file)
			- ContentView
			- AppFile 
		/Features (each feature gets a dedicated folder)
			/<Descriptive-Feature-Name>
				/API (contains a service file and request and response models for API)
					<Descriptive-Feature-Name>Service.swift
				/Models (contains important view models)
				/Views (contains SwiftUI views and related components)
					/Components (contains SwiftUI components for the views)
					<Descriptive-Feature-Name>View.swift
				/ViewModels
					<Descriptive-Feature-Name>ViewModel.swift
		/Coordinator (contains a coordinator for path related actions)
			AppCoordinator.swift
		/Extensions (custom extensions to native Swift and SwiftUI)
		/Utils (contains utilitarian functions)
	/ZanzarProjectTests (testing folder)
"""