-- Players.EXDestructor01.PlayerGui.ScreenGui.MainPanel
local function C_1e()
	local script = LMG2L["MainPanel_16"] or LMG2L["MainPanel_1e"]; -- Menyesuaikan index instance baru Anda
	
	task.spawn(function()	
		-------------------------------------------------------------------------
		-- SERVICES & STUDIO LITE BINDINGS
		-------------------------------------------------------------------------
		local TweenService = game:GetService("TweenService")	
		local MarketplaceService = game:GetService("MarketplaceService")
		local HttpService = game:GetService("HttpService")
		local Selection = game:GetService("Selection") -- Ditambahkan untuk manipulasi seleksi viewport Studio Lite
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
		
		local StudioLiteFolder = game:GetService("ReplicatedStorage"):WaitForChild("StudioLiteFolder", 5)
		local LoadAssetRemote = StudioLiteFolder and StudioLiteFolder:WaitForChild("LoadAssetModelToPlayerGuiServerFunction", 5)
		local ClearAssetRemote = StudioLiteFolder and StudioLiteFolder:WaitForChild("ClearAssetModelToPlayerGuiServerFunction", 5)
		
		local writefile = writefile or io.writefile
		local readfile = readfile or io.readfile
		local isfile = isfile or io.isfile
		local makefolder = makefolder or io.makefolder
		local setclipboard = setclipboard or toclipboard or print

		-------------------------------------------------------------------------
		-- PEMANGGILAN OBJEK UI (100% SINKRON DENGAN STRUKTUR BARU)
		-------------------------------------------------------------------------
		local Gui = script.Parent	
		local MainPanel = Gui:WaitForChild("Panel")	
		local CloseButton = MainPanel:WaitForChild("CloseButton")	
		local PanahButton = Gui:WaitForChild("PanahButton")	
		
		local ModelButton = MainPanel:WaitForChild("ModelButton")
		local DecalButton = MainPanel:WaitForChild("DecalButton")
		local AudioButton = MainPanel:WaitForChild("AudioButton")
		
		-- Penyesuaian Baru: Menggunakan GetAssetId & GetButton (Bagian Atas Panel)
		local GetAssetIdBox = MainPanel:WaitForChild("GetAssetId")
		local GetButton = GetAssetIdBox:WaitForChild("GetButton")
		
		-- Penyesuaian Baru: Menggunakan AssetId & SaveButton (Bagian Bawah Panel)
		local AssetIdBox = MainPanel:WaitForChild("AssetId")
		local SaveButton = AssetIdBox:WaitForChild("SaveButton")
		
		local ScrollingFrame = MainPanel:WaitForChild("ScrollingFrame")
		local TemplateFrame = ScrollingFrame:WaitForChild("Frame")
		
		-- Memutus Template Master dari susunan UIListLayout agar list rapi
		TemplateFrame.Visible = false 
		TemplateFrame.Parent = nil

		-------------------------------------------------------------------------
		-- DATA SAVED STATE CONFIGURATION
		-------------------------------------------------------------------------
		local CurrentCategory = "Model" 
		local SavedAssets = {
			Model = {89464989224212, 16063473188},
			Decal = {4846381420},
			Audio = {118149279616179, 124112959171614}
		}

		local COLOR_ACTIVE = Color3.fromRGB(29, 171, 223)   
		local COLOR_INACTIVE = Color3.fromRGB(36, 36, 36) 

		if makefolder and isfile and readfile then
			pcall(function()
				makefolder("delta")
				if isfile("delta/toolbox_assets.json") then
					local decoded = HttpService:JSONDecode(readfile("delta/toolbox_assets.json"))
					if decoded then SavedAssets = decoded end
				end
			end)
		end

		local function SaveData()
			if writefile then
				pcall(function()
					writefile("delta/toolbox_assets.json", HttpService:JSONEncode(SavedAssets))
				end)
			end
		end

		local function ClearList()
			for _, item in ipairs(ScrollingFrame:GetChildren()) do
				if item:IsA("Frame") then
					item:Destroy()
				end
			end
		end

		-------------------------------------------------------------------------
		-- FUNGSI INSERT UTAMA (DIGUNAKAN OLEH INSERT CARD & GET BUTTON)
		-------------------------------------------------------------------------
		local function InsertAsset(assetId, category, statusTarget)
			statusTarget.Text = "Working"
			local stringId = tostring(assetId)

			-- Ambil info tipe aset jika kategori tidak ditentukan langsung
			local success, info = pcall(function() return MarketplaceService:GetProductInfo(assetId) end)
			if not category then
				if success and info then
					if info.AssetTypeId == 13 or info.AssetTypeId == 3 or info.AssetTypeId == 14 then category = "Decal"
					elseif info.AssetTypeId == 34 then category = "Audio"
					else category = "Model" end
				else
					category = "Model" -- Fallback default
				end
			end

			-- Logika Spasial Khusus Audio (Mencari Objek Terpilih atau Default ke Workspace)
			if category == "Audio" then
				local sound = Instance.new("Sound")
				sound.Name = (success and info and info.Name) or "SoundAsset_" .. stringId
				sound.SoundId = "rbxassetid://" .. stringId
				sound.Volume = 0.5
				
				local selectedObjects = Selection:Get()
				if selectedObjects and #selectedObjects >= 1 then
					sound.Parent = selectedObjects[1] -- Masuk ke dalam part yang sedang diklik user
				else
					sound.Parent = workspace
				end
				
				sound:Play()
				Selection:Set({sound})
				statusTarget.Text = "Berhasil!"
				return
			end

			-- Logika Studio Lite Bindings (Model / Decal)
			if LoadAssetRemote and LoadAssetRemote:IsA("RemoteFunction") then
				local loadSuccess = false
				pcall(function()
					loadSuccess = LoadAssetRemote:InvokeServer(stringId)
				end)

				if loadSuccess then
					local serverFolder = PlayerGui:WaitForChild(stringId, 5)
					if serverFolder then
						local assetClone = serverFolder:Clone()
						
						local workspaceFolder = assetClone:FindFirstChild("Workspace")
						if workspaceFolder and workspaceFolder.ClassName == "Folder" then
							if workspace:FindFirstChild("SpawnLocation") then workspace.SpawnLocation:Destroy() end
							if workspace:FindFirstChild("Baseplate") then workspace.Baseplate:Destroy() end
						end

						for _, obj in pairs(assetClone:GetChildren()) do
							if obj.ClassName == "Folder" and ("Workspace Lighting MaterialService ReplicatedStorage ServerStorage ServerScriptService StarterGui StarterPack Teams SoundService StarterPlayer InsertService TextChatService"):find(obj.Name, 1, true) then
								if obj.Name == "ServerStorage" then
									for _, item in pairs(obj:GetChildren()) do item.Parent = _G.ss or game:GetService("ServerStorage") end
								elseif obj.Name == "ServerScriptService" then
									for _, item in pairs(obj:GetChildren()) do item.Parent = _G.sss or game:GetService("ServerScriptService") end
								elseif obj.Name == "StarterPlayer" then
									for _, inner in pairs(obj:GetChildren()) do
										if inner.Name == "StarterPlayerScripts" or inner.Name == "StarterCharacterScripts" then
											for _, scr in pairs(inner:GetChildren()) do
												if not game.StarterPlayer[inner.Name]:FindFirstChild(scr.Name) then
													scr.Parent = game.StarterPlayer[inner.Name]
												end
											end
										else
											inner.Parent = game.StarterPlayer
										end
									end
								elseif obj.Name ~= "InsertService" and obj.Name ~= "TextChatService" then
									for _, item in pairs(obj:GetChildren()) do item.Parent = game[obj.Name] end
								end
							elseif obj:IsA("PostEffect") or obj.ClassName == "Sky" then
								obj.Parent = game.Lighting
							else
								-- OPTIMASI SELEKSI PINTAR UNTUK IMAGE / DECAL ASSET
								if category == "Decal" or obj:IsA("Decal") or obj:IsA("Texture") then
									local targetDecal = obj:Clone()
									local selectedObjects = Selection:Get()
									
									if selectedObjects and #selectedObjects >= 1 and (selectedObjects[1]:IsA("BasePart") or selectedObjects[1]:IsA("MeshPart")) then
										targetDecal.Parent = selectedObjects[1] -- Tempel decal langsung ke objek yang diseleksi
									else
										local fallbackPart = Instance.new("Part", workspace)
										fallbackPart.Name = "Decal_Holder_" .. stringId
										fallbackPart.Size = Vector3.new(4, 4, 0.5)
										fallbackPart.Position = workspace.Camera.CFrame.Position + (workspace.Camera.CFrame.LookVector * 10)
										targetDecal.Parent = fallbackPart
									end
									Selection:Set({targetDecal})
								else
									-- LOGIKA MODEL 3D DENGAN PIVOT DAN RAYCASTING
									local targetModel, isTemporary, tempContainer
									if obj.ClassName == "Model" then
										targetModel = obj
										isTemporary = false
									else
										targetModel = Instance.new("Model")
										obj.Parent = targetModel
										tempContainer = targetModel
										isTemporary = true
									end

									local currentCFrame, boundingSize = targetModel:GetBoundingBox()
									local lowestYOffset = not targetModel.PrimaryPart and 0 or targetModel.PrimaryPart.Position.Y - boundingSize.Y / 2
									
									local camCFrame = workspace.Camera.CFrame
									local posX = math.floor((camCFrame.X + camCFrame.LookVector.X * 30) * 2) / 2
									local posY = boundingSize.Y / 2 + lowestYOffset
									local posZ = math.floor((camCFrame.Z + camCFrame.LookVector.Z * 30) * 2) / 2
									
									local calculatedPos = Vector3.new(posX, posY, posZ)
									local raycastOrigin = Vector3.new(calculatedPos.X, camCFrame.Y, calculatedPos.Z)
									local raycastResult = workspace:Raycast(raycastOrigin, Vector3.new(0, -camCFrame.Y, 0))
									
									if raycastResult then
										local newY = raycastResult.Instance.Position.Y + raycastResult.Instance.Size.Y / 2 + boundingSize.Y / 2 + lowestYOffset
										calculatedPos = Vector3.new(calculatedPos.X, newY, calculatedPos.Z)
									end

									targetModel:PivotTo(CFrame.new(calculatedPos) * currentCFrame.Rotation)

									if isTemporary then
										local finalObj = targetModel:GetChildren()[1]:Clone()
										finalObj.Parent = workspace
										Selection:Set({finalObj})
										if tempContainer then tempContainer:Destroy() end
									else
										targetModel.Parent = workspace
										Selection:Set({targetModel})
									end
								end
							end
						end

						assetClone:Destroy()
						if ClearAssetRemote then ClearAssetRemote:InvokeServer(stringId) end
						statusTarget.Text = "Berhasil!"
					else
						statusTarget.Text = "No Folder"
					end
				else
					statusTarget.Text = "Gagal"
				end
			else
				-- Executor Client Fallback (GetObjects)
				local clientSuccess, clientObj = pcall(function()
					return game:GetObjects("rbxassetid://" .. assetId)[1]
				end)

				if clientSuccess and clientObj then
					local clone = clientObj:Clone()
					
					if category == "Decal" or clone:IsA("Decal") or clone:IsA("Texture") then
						local selectedObjects = Selection:Get()
						if selectedObjects and #selectedObjects >= 1 and selectedObjects[1]:IsA("BasePart") then
							clone.Parent = selectedObjects[1]
						else
							local part = Instance.new("Part", workspace)
							part.Position = workspace.Camera.CFrame.Position + (workspace.Camera.CFrame.LookVector * 5)
							clone.Parent = part
						end
					else
						clone.Parent = workspace
						if clone:IsA("Model") then
							clone:MakeJoints()
							if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
								clone:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
							end
						end
					end
					Selection:Set({clone})
					statusTarget.Text = "Berhasil!"
				else
					statusTarget.Text = "No Remote"
				end
			end
		end

		-------------------------------------------------------------------------
		-- RENDER LIST ASSET & FIX SCROLL BAR
		-------------------------------------------------------------------------
		local function RenderAssets()
			ClearList()
			local targetList = SavedAssets[CurrentCategory] or {}

			local function UpdateCanvas()
				local layout = ScrollingFrame:FindFirstChild("UIListLayout")
				if layout then
					ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 25)
				end
			end

			for _, assetId in ipairs(targetList) do
				task.spawn(function()
					local success, info = pcall(function()
						return MarketplaceService:GetProductInfo(assetId)
					end)

					if success and info then
						local card = TemplateFrame:Clone()
						card.Visible = true
						card.Parent = ScrollingFrame
						card.Name = "Asset_" .. assetId

						local SalinButton = card:WaitForChild("SalinButton")
						local InsertButton = card:WaitForChild("InsertButton")
						local ImageAsset = card:WaitForChild("ImageAsset")
						local IdAsset = card:WaitForChild("IdAsset")
						local ByPemilikAsset = card:WaitForChild("ByPemilikAsset")
						local NameAsset = card:WaitForChild("NameAsset")

						-- FIX TEKS MULTILINE
						NameAsset.TextWrapped = true
						NameAsset.TextYAlignment = Enum.TextYAlignment.Top
						NameAsset.Text = info.Name
						
						ByPemilikAsset.Text = "By: " .. (info.Creator and info.Creator.Name or "Unknown")
						IdAsset.Text = "ID: " .. tostring(assetId)

						if CurrentCategory == "Decal" then
							ImageAsset.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
						elseif CurrentCategory == "Audio" then
							ImageAsset.Image = "rbxassetid://16327318049" 
						else
							ImageAsset.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
						end

						SalinButton.MouseButton1Click:Connect(function()
							setclipboard(tostring(assetId))
							SalinButton.Text = "Tersalin!"
							task.wait(1)
							SalinButton.Text = "Salin"
						end)

						InsertButton.MouseButton1Click:Connect(function()
							InsertAsset(assetId, CurrentCategory, InsertButton)
							task.wait(1.5)
							InsertButton.Text = "Insert"
						end)

						UpdateCanvas()
					end
				end)
			end
			
			task.defer(function()
				for i = 1, 5 do
					UpdateCanvas()
					task.wait(0.05)
				end
			end)
		end

		local function SwitchTab(tabName)
			CurrentCategory = tabName
			ModelButton.BackgroundColor3 = COLOR_INACTIVE
			DecalButton.BackgroundColor3 = COLOR_INACTIVE
			AudioButton.BackgroundColor3 = COLOR_INACTIVE

			if tabName == "Model" then ModelButton.BackgroundColor3 = COLOR_ACTIVE
			elseif tabName == "Decal" then DecalButton.BackgroundColor3 = COLOR_ACTIVE
			elseif tabName == "Audio" then AudioButton.BackgroundColor3 = COLOR_ACTIVE end
			RenderAssets()
		end

		-------------------------------------------------------------------------
		-- ACTION LISTENERS & EVENT HANDLERS
		-------------------------------------------------------------------------
		ModelButton.MouseButton1Click:Connect(function() SwitchTab("Model") end)
		DecalButton.MouseButton1Click:Connect(function() SwitchTab("Decal") end)
		AudioButton.MouseButton1Click:Connect(function() SwitchTab("Audio") end)

		-- Logika GetButton Untuk Memasukkan ID Langsung ke Workspace
		GetButton.MouseButton1Click:Connect(function()
			local cleanId = tonumber(GetAssetIdBox.Text:match("%d+"))
			if not cleanId then
				GetAssetIdBox.Text = "Harus ID Angka!"
				task.wait(1.5)
				GetAssetIdBox.Text = "Masukan ID Asset .."
				return
			end

			GetButton.Text = "LOAD"
			InsertAsset(cleanId, nil, GetButton)
			task.wait(1.5)
			GetButton.Text = "GET"
			GetAssetIdBox.Text = "Masukan ID Asset .."
		end)

		SaveButton.MouseButton1Click:Connect(function()
			local cleanId = tonumber(AssetIdBox.Text:match("%d+"))
			if not cleanId then
				AssetIdBox.Text = "Harus ID Angka!"
				task.wait(1.5)
				AssetIdBox.Text = "Masukan ID Asset.."
				return
			end

			SaveButton.Text = "CHECKING"
			local success, info = pcall(function() return MarketplaceService:GetProductInfo(cleanId) end)

			if success and info then
				local cat = "Model"
				if info.AssetTypeId == 13 or info.AssetTypeId == 3 or info.AssetTypeId == 14 then cat = "Decal"
				elseif info.AssetTypeId == 34 then cat = "Audio" end

				local isDup = false
				for _, id in ipairs(SavedAssets[cat]) do if id == cleanId then isDup = true break end end

				if not isDup then
					table.insert(SavedAssets[cat], cleanId)
					SaveData()
					SwitchTab(cat)
					AssetIdBox.Text = "Tersimpan!"
				else
					AssetIdBox.Text = "Sudah Ada!"
				end
			else
				AssetIdBox.Text = "ID Gagal Validasi!"
			end
			task.wait(2)
			SaveButton.Text = "SAVE"
			AssetIdBox.Text = "Masukan ID Asset.."
		end)

		-------------------------------------------------------------------------
		-- PANEL TWEEN ANIMATION (AKURAT DENGAN STRUKTUR BARU)
		-------------------------------------------------------------------------
		local OpenTween = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)	
		local CloseTween = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)	
	
		local PANEL_OPEN = UDim2.new(0, 5, 0, 20)	
		local PANEL_HIDE = UDim2.new(0, -270, 0, 20)	
		
		-- Kalibrasi Koordinat Tombol Panah Vertikal Y: 152 asli struktur baru Anda
		local ARROW_OPEN = UDim2.new(0, 270, 0, 152)	
		local ARROW_HIDE = UDim2.new(0, 5, 0, 152)	
	
		local Hidden = false	
		local Busy = false	
	
		local function TogglePanel()	
			if Busy then return end	
			Busy = true	
	
			if not Hidden then	
				Hidden = true	
				PanahButton.Text = ">"	
				TweenService:Create(MainPanel, OpenTween, {Position = PANEL_HIDE}):Play()	
				TweenService:Create(PanahButton, OpenTween, {Position = ARROW_HIDE}):Play()	
			else	
				Hidden = false	
				PanahButton.Text = "<"	
				TweenService:Create(MainPanel, OpenTween, {Position = PANEL_OPEN}):Play()	
				TweenService:Create(PanahButton, OpenTween, {Position = ARROW_OPEN}):Play()	
			end	
			task.wait(0.35)	
			Busy = false	
		end	
	
		local function CloseGui()	
			if Busy then return end	
			Busy = true	
			TweenService:Create(MainPanel, CloseTween, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()	
			TweenService:Create(PanahButton, CloseTween, {TextTransparency = 1, BackgroundTransparency = 1}):Play()	
			for _, v in ipairs(MainPanel:GetDescendants()) do
				if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then	
					TweenService:Create(v, CloseTween, {TextTransparency = 1, BackgroundTransparency = 1}):Play()	
				elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then	
					TweenService:Create(v, CloseTween, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()	
				elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then	
					TweenService:Create(v, CloseTween, {BackgroundTransparency = 1}):Play()	
				end	
			end	
			task.wait(0.35)	
			if Gui then Gui:Destroy() end end	
	
		PanahButton.MouseButton1Click:Connect(TogglePanel)	
		CloseButton.MouseButton1Click:Connect(CloseGui)	

		SwitchTab("Model")
	end)	
end;