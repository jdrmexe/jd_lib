-- Sling Configuration Editor
-- ox_lib input UI + object_gizmo placement.

local Editor = {
    active = false,
    ped = nil,
    previewWeapon = nil,
    selectedBone = nil,
    weaponModel = nil,
    weaponName = nil,
    position = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
    camera = nil,
}

-- Human-friendly GTA skeleton bones commonly useful for slings.
local BoneMap = {
    { label = 'Spine / Lower Back', value = '23553', boneName = 'SKEL_Spine0' },
    { label = 'Spine / Back', value = '24816', boneName = 'SKEL_Spine1' },
    { label = 'Chest', value = '24817', boneName = 'SKEL_Spine2' },
    { label = 'Upper Chest', value = '24818', boneName = 'SKEL_Spine3' },
    { label = 'Left Clavicle', value = '10706', boneName = 'SKEL_L_Clavicle' },
    { label = 'Right Clavicle', value = '64729', boneName = 'SKEL_R_Clavicle' },
    { label = 'Left Upper Arm', value = '45509', boneName = 'SKEL_L_UpperArm' },
    { label = 'Right Upper Arm', value = '40269', boneName = 'SKEL_R_UpperArm' },
    { label = 'Left Forearm', value = '61163', boneName = 'SKEL_L_Forearm' },
    { label = 'Right Forearm', value = '28252', boneName = 'SKEL_R_Forearm' },
    { label = 'Left Thigh', value = '58271', boneName = 'SKEL_L_Thigh' },
    { label = 'Right Thigh', value = '51826', boneName = 'SKEL_R_Thigh' },
}

local function notify(description, type)
    if lib then
        lib.notify({
            title = 'Sling Editor',
            description = description,
            type = type or 'inform'
        })
    elseif Config.EnableNotifications then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(description)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function deleteEntity(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function requestModel(model)
    if not model or model == '' then return false end

    local hash = type(model) == 'string' and joaat(model) or model
    if hash == 0 or not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false
    end

    if lib and lib.requestModel then
        local ok, result = pcall(lib.requestModel, hash, 10000)
        if ok and result then return result end
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasModelLoaded(hash) and hash or false
end

local function cleanupEditor(silent)
    deleteEntity(Editor.previewWeapon)
    deleteEntity(Editor.ped)

    if Editor.camera and DoesCamExist(Editor.camera) then
        RenderScriptCams(false, true, 250, true, true)
        DestroyCam(Editor.camera, false)
    end
    Editor.camera = nil

    Editor.active = false
    Editor.previewWeapon = nil
    Editor.ped = nil
    Editor.selectedBone = nil
    Editor.weaponModel = nil
    Editor.weaponName = nil
    Editor.position = vector3(0.0, 0.0, 0.0)
    Editor.rotation = vector3(0.0, 0.0, 0.0)

    if not silent then
        notify('Editor closed.', 'inform')
    end
end

local function loadPreviewPedModel()
    local candidates = {}

    -- Always prefer the male freemode MP ped for a consistent GTA skeleton.
    candidates[#candidates + 1] = 'mp_m_freemode_01'
    if Config.PreviewPedModel and Config.PreviewPedModel ~= `mp_m_freemode_01` then candidates[#candidates + 1] = Config.PreviewPedModel end
    for _, model in ipairs(Config.PreviewPedFallbackModels or {}) do
        candidates[#candidates + 1] = model
    end
    candidates[#candidates + 1] = 'a_m_y_business_01'
    candidates[#candidates + 1] = 'mp_m_freemode_01'

    for _, candidate in ipairs(candidates) do
        local hash = requestModel(candidate)
        if hash then return hash end
    end

    return false
end

local function spawnPreviewPed()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local model = loadPreviewPedModel()

    if not model then
        notify('Could not load a valid preview ped model.', 'error')
        return false
    end

    local x = playerCoords.x + forward.x * 3.5
    local y = playerCoords.y + forward.y * 3.5
    local z = playerCoords.z + 2.0
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    if foundGround then z = groundZ end

    local heading = GetEntityHeading(playerPed) + 180.0
    Editor.ped = CreatePed(4, model, x, y, z, heading, false, false)

    if not DoesEntityExist(Editor.ped) then
        RequestModel(model)
        Wait(250)
        Editor.ped = CreatePed(4, model, x, y, z, heading, false, false)
    end

    if not DoesEntityExist(Editor.ped) then
        notify('Failed to create the preview ped.', 'error')
        return false
    end

    SetEntityAsMissionEntity(Editor.ped, true, true)
    FreezeEntityPosition(Editor.ped, true)
    SetEntityInvincible(Editor.ped, true)
    SetBlockingOfNonTemporaryEvents(Editor.ped, true)
    SetPedCanRagdoll(Editor.ped, false)
    SetPedKeepTask(Editor.ped, true)
    SetEntityCollision(Editor.ped, true, true)
    FreezeEntityPosition(Editor.ped, true)

    -- Put the preview exactly on the ground instead of floating at the player's Z.
    PlaceObjectOnGroundProperly(Editor.ped)
    local pedCoords = GetEntityCoords(Editor.ped)
    local groundFound, floorZ = GetGroundZFor_3dCoord(pedCoords.x, pedCoords.y, pedCoords.z + 2.0, false)
    if groundFound then
        SetEntityCoordsNoOffset(Editor.ped, pedCoords.x, pedCoords.y, floorZ, false, false, false)
    end

    -- Blender-like preview camera: the editor becomes a small 3D studio around the ped.
    local c = GetEntityCoords(Editor.ped)
    local camPos = GetOffsetFromEntityInWorldCoords(Editor.ped, 3.2, 5.2, 1.9)
    Editor.camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Editor.camera, camPos.x, camPos.y, camPos.z)
    PointCamAtEntity(Editor.camera, Editor.ped, 0.0, 0.0, 1.05, true)
    SetCamFov(Editor.camera, 48.0)
    SetCamActive(Editor.camera, true)
    RenderScriptCams(true, true, 350, true, true)

    SetModelAsNoLongerNeeded(model)

    return true
end

local function chooseBone()
    local options = {}
    for _, bone in ipairs(BoneMap) do
        options[#options + 1] = {
            value = bone.value,
            label = bone.label,
            description = ('%s (%s)'):format(bone.boneName, bone.value)
        }
    end

    local input = lib.inputDialog('Sling Editor — Bone', {
        {
            type = 'select',
            label = 'Attachment bone',
            description = 'Choose the ped bone the weapon will be attached to.',
            options = options,
            required = true,
            searchable = true,
        }
    }, { allowCancel = true, size = 'md' })

    if not input then return false end

    local boneId = tonumber(input[1])
    for _, bone in ipairs(BoneMap) do
        if tonumber(bone.value) == boneId then
            Editor.selectedBone = {
                id = boneId,
                name = bone.boneName,
                label = bone.label,
            }
            return true
        end
    end

    return false
end

local function chooseWeapon()
    local input = lib.inputDialog('Sling Editor — Weapon', {
        {
            type = 'input',
            label = 'Weapon object model',
            description = 'The object model that should appear on the ped.',
            placeholder = 'w_ar_servicecarbine',
            required = true,
            default = Editor.weaponModel or '',
        },
        {
            type = 'input',
            label = 'Weapon name / hash',
            description = 'Optional GTA weapon name used in the generated config.',
            placeholder = 'WEAPON_SERVICECARBINE',
            default = Editor.weaponName or '',
        }
    }, { allowCancel = true, size = 'md' })

    if not input then return false end

    local model = tostring(input[1] or ''):lower():gsub('%.ydr$', '')
    local weaponName = tostring(input[2] or ''):upper():gsub('%.YDR$', '')

    if model == '' then
        notify('Enter a weapon object model, e.g. w_ar_servicecarbine.', 'error')
        return false
    end

    local hash = requestModel(model)
    if not hash then
        notify(('Weapon model ^1%s^7 could not be loaded.'):format(model), 'error')
        return false
    end
    SetModelAsNoLongerNeeded(hash)

    Editor.weaponModel = model
    Editor.weaponName = weaponName ~= '' and weaponName or nil
    return true
end

local function spawnWeaponPreview()
    deleteEntity(Editor.previewWeapon)

    local model = requestModel(Editor.weaponModel)
    if not model then
        notify(('Failed to load weapon model %s.'):format(Editor.weaponModel), 'error')
        return false
    end

    local boneIndex = GetPedBoneIndex(Editor.ped, Editor.selectedBone.id)
    if boneIndex == -1 then
        notify(('Bone %s is not present on the preview ped.'):format(Editor.selectedBone.name), 'error')
        SetModelAsNoLongerNeeded(model)
        return false
    end

    local bonePos = GetWorldPositionOfEntityBone(Editor.ped, boneIndex)
    Editor.previewWeapon = CreateObject(model, bonePos.x, bonePos.y, bonePos.z, false, false, false)

    if not DoesEntityExist(Editor.previewWeapon) then
        notify('Failed to create the preview weapon object.', 'error')
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(Editor.previewWeapon, true, true)
    SetEntityCollision(Editor.previewWeapon, false, false)
    FreezeEntityPosition(Editor.previewWeapon, false)
    SetModelAsNoLongerNeeded(model)

    return true
end

local function getBoneWorldRotation(boneIndex)
    if GetEntityBoneRotation then
        local rotation = GetEntityBoneRotation(Editor.ped, boneIndex)
        if rotation then return rotation end
    end
    return GetEntityRotation(Editor.ped, 2)
end

local function applyGizmoResult(result)
    if not result or not DoesEntityExist(Editor.previewWeapon) then
        return false
    end

    local coords = result.position or result.coords
    local rotation = result.rotation or result.rot

    if not coords then
        coords = GetEntityCoords(Editor.previewWeapon)
    end
    if not rotation then
        rotation = GetEntityRotation(Editor.previewWeapon, 2)
    end

    local boneIndex = GetPedBoneIndex(Editor.ped, Editor.selectedBone.id)
    if boneIndex == -1 then return false end

    -- The gizmo works in world space. Convert the final gizmo position back to
    -- ped-local coordinates; the preview ped is frozen, so these values remain
    -- stable and are suitable for AttachEntityToEntity.
    local offset = GetOffsetFromEntityGivenWorldCoords(Editor.ped, coords.x, coords.y, coords.z)
    local boneRotation = getBoneWorldRotation(boneIndex)

    Editor.position = vector3(offset.x, offset.y, offset.z)
    Editor.rotation = vector3(
        rotation.x - boneRotation.x,
        rotation.y - boneRotation.y,
        rotation.z - boneRotation.z
    )

    -- Normalize rotation values to make the generated config clean.
    Editor.rotation = vector3(
        ((Editor.rotation.x + 180.0) % 360.0) - 180.0,
        ((Editor.rotation.y + 180.0) % 360.0) - 180.0,
        ((Editor.rotation.z + 180.0) % 360.0) - 180.0
    )

    return true
end

local function attachPreview()
    if not DoesEntityExist(Editor.previewWeapon) then return end

    local boneIndex = GetPedBoneIndex(Editor.ped, Editor.selectedBone.id)
    AttachEntityToEntity(
        Editor.previewWeapon,
        Editor.ped,
        boneIndex,
        Editor.position.x,
        Editor.position.y,
        Editor.position.z,
        Editor.rotation.x,
        Editor.rotation.y,
        Editor.rotation.z,
        true,
        true,
        false,
        true,
        2,
        true
    )
end

local function useGizmo()
    if GetResourceState('object_gizmo') ~= 'started' then
        notify('object_gizmo is not started. Start it before using /slingconfig.', 'error')
        return false
    end

    if not DoesEntityExist(Editor.previewWeapon) then return false end

    -- object_gizmo provides the actual 3D translation/rotation editor; ox_lib
    -- handles the menus, inputs and notifications around it.
    local result = exports.object_gizmo:useGizmo(Editor.previewWeapon)
    return applyGizmoResult(result)
end

local function generateConfigEntry()
    local weaponName = Editor.weaponName or 'WEAPON_NAME_HERE'
    local entry = table.concat({
        '    {',
        ('        weapon = `%s`,'):format(weaponName),
        ('        model = `%s`,'):format(Editor.weaponModel),
        ('        bone = %d,'):format(Editor.selectedBone.id),
        ('        offset = vector3(%.4f, %.4f, %.4f),'):format(Editor.position.x, Editor.position.y, Editor.position.z),
        ('        rotation = vector3(%.2f, %.2f, %.2f)'):format(Editor.rotation.x, Editor.rotation.y, Editor.rotation.z),
        '    }'
    }, '\n')

    return entry
end

local function showResult()
    local entry = generateConfigEntry()
    print('^2===== JD SLING CONFIG ENTRY =====^7')
    print(entry)
    print('^2==================================^7')

    lib.alertDialog({
        header = 'Sling configuration ready',
        content = ('```lua\n%s\n```\n\nThe generated entry was also printed to your F8 console.'):format(entry),
        centered = true,
        cancel = false,
        labels = { confirm = 'Done' }
    })
end

local function runEditor()
    if Editor.active then
        notify('The editor is already open.', 'error')
        return
    end

    if not spawnPreviewPed() then return end
    Editor.active = true

    notify('3D preview ready. Choose a ped bone from the ox_lib menu.', 'inform')

    if not chooseBone() then
        cleanupEditor(true)
        return
    end

    if not chooseWeapon() then
        cleanupEditor(true)
        return
    end

    if not spawnWeaponPreview() then
        cleanupEditor(true)
        return
    end

    notify(('Placing %s on %s.'):format(Editor.weaponModel, Editor.selectedBone.label), 'success')
    notify('Blender-style 3D preview: W = move, R = rotate, Q = world/local, LAlt = ground, Enter = save.', 'inform')

    if not useGizmo() then
        cleanupEditor(true)
        return
    end

    attachPreview()
    showResult()
    cleanupEditor(true)
end

RegisterCommand('slingconfig', function()
    CreateThread(runEditor)
end, false)

exports('StartSlingEditor', function()
    CreateThread(runEditor)
end)

exports('StopSlingEditor', function()
    cleanupEditor(true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanupEditor(true)
    end
end)
