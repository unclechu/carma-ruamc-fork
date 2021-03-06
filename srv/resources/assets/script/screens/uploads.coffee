# Bulk uploads screen handlers, inline-uploader widget handlers.
#
# Uses "Attachment" model and /upload/Case/[bulk|<n>]/files server
# handlers.

{$, _, ko} = require "carma/vendor"

upl = require "carma/lib/upload"
mu  = require "carma/model/utils"

template = require "carma-tpl/screens/uploads.pug"

# Destructively add a reference to attachment:<attId> to files field
# of a case instance object
#
# Return true if a reference to this attachment is already present
#
# TODO This might be replaced by a regular reference-adding routine
addAttIdToCaseObj = (attId, caseObj) ->
  ref = "Attachment:" + attId
  if caseObj.files? && caseObj.files.length > 0
    # No dupe references
    if caseObj.files.search(ref) == -1
      caseObj.files = caseObj.files + "," + ref
      return true
    else
      return false
  else
    caseObj.files = ref
    return true

# Remove an attachment reference from case, provided file's bvm and
# case number.
detachFromCase = (bvm, caseId) ->
  caseUrl = "/_/Case/" + caseId
  attId = bvm.aid()
  ref = "Attachment:" + attId

  $.getJSON(caseUrl).
    done((res) ->
      newFiles = _.without(res.files.split(","), ref).join(",")
      $.putJSON(caseUrl, {files: newFiles}).
        done(() -> bvm.cases.remove caseId))

# Attach a file to a case, provided file's bvm and a field
# containing case number. Check for dupes/unknown cases. Set af's
# validity in case of error. Push new case id to bvm.cases.
attachToCase = (bvm, af) ->
  caseId = parseInt af.val()
  caseUrl = "/_/Case/" + caseId
  attId = bvm.aid()

  if caseId.length == 0
    af[0].setCustomValidity "Не задан номер кейса"
    return

  $.getJSON(caseUrl).
    fail(() ->
      af[0].setCustomValidity "Кейс не найден"
    ).
    done((res) ->
      # Patch "files" field of the object and send it back to server
      # using regular CRUD interface
      notDupe = addAttIdToCaseObj attId, res
      if !notDupe
        af[0].setCustomValidity "К этому кейсу данный файл уже прикреплён"
      else
        # Clear input (not gonna fix it)
        af.val("")
        # Store new reference
        $.putJSON(caseUrl, {files: res.files}).
          done(() -> bvm.cases.push caseId))

# Upload new attachment, render file progress bar and whistles.
# Argument is a File object.
sendFile = (file, alwaysCb = (->)) ->
  if upl.checkFileSize(file)
    do alwaysCb
    return

  uid = _.uniqueId "upload-"

  # A box for this upload, with a progress bar and whistles
  box = $ $("#upload-box-template").clone().html()
  box.attr "id", uid
  do box.hide
  box.appendTo $("#uploaded-files")
  do box.fadeIn

  # A small KVM for user interaction
  bvm =
    msg      : ko.observable "Выполняю загрузку…"
    filename : ko.observable file.name
    aid      : ko.observable null
    # Array of case ids this file has been attached to
    cases    : ko.observableArray()
    # Array of unknown case ids from filename
    unknown  : ko.observableArray()
    # True if the file was uploaded as a duplicate
    dupe     : ko.observable false
    # Allow attaching to extra cases
    attach : ko.observable false
  ko.applyBindings bvm, $(box)[0]

  # Upload the file asynchronously
  upl.ajaxUpload "/upload/Case/bulk/files/",
                 file,
                 xhr: upl.progressXHR box.find ".progress"

    .always () ->
      do box.find(".progress").fadeOut
      box.removeClass "alert-info"
      do alwaysCb

    .fail () ->
      box.addClass "alert-danger"
      bvm.msg "Во время загрузки произошла критическая ошибка"

    .done (res) ->
      bvm.aid res.attachment.id
      bvm.filename res.attachment.filename
      bvm.dupe res.dupe

      for t in res.targets
        bvm.cases.push t[1]
      for t in res.unknown
        bvm.unknown.push t[1]

      if bvm.cases().length == 0
        box.addClass "alert-danger"
        bvm.msg "Файл загружен, но номера кейсов не распознаны"
      else if bvm.unknown().length > 0
        box.addClass "alert-warning"
        bvm.msg "Файл загружен, но некоторые номера кейсов не распознаны"
      else
        box.addClass "alert-success"
        bvm.msg "Файл успешно загружен"

      bvm.attach true

      # Activate "add case" link
      box.find(".attach-button").click () ->
        do $(this).hide
        do box.find(".attach-form").show().find(".attach-field").focus
        false
      box.find(".attach-field").blur () ->
        return if $(this).val().length isnt 0
        do $(this).parents(".attach-form").hide
        do box.find(".attach-button").show

      # "Delete case" links
      box.on "click", ".detach-button", () ->
        detachFromCase bvm, $(this).data "target"
        false

      # Hook up case add routine for input field
      box.find(".attach-form").submit (e) ->
        af = $(this).find ".attach-field"
        res = attachToCase bvm, af
        false

      # Forget existing validity violations when case number changes
      box.find(".attach-field").change () ->
        $(this)[0].setCustomValidity ""

      box.data "bvm", bvm

# Render file browser widget, setup all hooks and screen-global
# handlers.
# TODO refactor spagetti of jquery with knockout
renderUploadsForm = (viewName, args) ->
  $("#upload-files-tip").tooltip()
  $("#upload-cleanup-tip").tooltip()

  $("#upload-cleanup").click () ->
    $("#uploaded-files .alert-success").slideUp()

  kvm =
    filesToUpload: ko.observableArray []
    isProcessing: ko.observable no

    uploadHandler: ->
      files = kvm.filesToUpload()
      return if files.length is 0
      kvm.filesToUpload []
      kvm.isProcessing yes

      Promise.all ((new Promise (cb) -> sendFile file, cb) for file in files)
        .then -> kvm.isProcessing no

  ko.applyBindings kvm, document.getElementById "upload-files-form"

module.exports =
  { constructor: renderUploadsForm
  , template
  }
