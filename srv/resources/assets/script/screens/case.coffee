define [ "utils"
       , "hotkeys"
       , "text!tpl/screens/case.html"
       , "text!tpl/fields/form.html"
       , "lib/ws"
       , "model/utils"
       , "model/main"
       , "components/contract"
       ],
  (utils, hotkeys, tpl, Flds, WS, mu, main, Contract) ->
    utils.build_global_fn 'pickPartnerBlip', ['map']

    flds =  $('<div/>').append($(Flds))
    # Case view (renders to #left, #center and #right as well)
    setupCaseMain = (viewName, args) -> setupCaseModel viewName, args

    setupCaseModel = (viewName, args) ->
      kaze = {}
      # Bootstrap case data to load proper view for Case model
      # depending on the program
      if args.id
        $.bgetJSON "/_/Case/#{args.id}", (rsp) -> kaze = rsp

      kvm = main.modelSetup("Case") viewName, args,
                         permEl       : "case-permissions"
                         focusClass   : "focusable"
                         slotsee      : ["case-number",
                                         "case-program-description",
                                         "case-car-description"]
                         groupsForest : "center"
                         defaultGroup : "default-case"
                         modelArg     : "ctr:#{kaze.program}"

      # TODO The server should notify the client about new actions
      # appearing in the case instead of explicit subscription
      kvm["caseStatusSync"]?.subscribe (nv) ->
        if !nv
          kvm['renderActions']?()

      ctx = {fields: (f for f in kvm._meta.model.fields when f.meta?.required)}
      setupCommentsHandler kvm

      Contract.setup "contract", kvm

      $("#empty-fields-placeholder").html(
          Mustache.render($(flds).find("#empty-fields-template").html(), ctx))

      ko.applyBindings(kvm, el("empty-fields"))


      # Render service picker
      #
      # We use Bootstrap's glyphs if "icon" key is set in dictionary
      # entry.
      $("#service-picker-container").html(
        Mustache.render(
          $(flds).find("#service-picker-template").html(),
            {dictionary: utils.newComputedDict("iconizedServiceTypes")
            ,drop: 'up'
            }))

      hotkeys.setup()
      kvm = global.viewsWare[viewName].knockVM

      # True if any of of required fields are missing a value
      do (kvm) ->
        kvm['hasMissingRequireds'] = ko.computed ->
          nots = (i for i of kvm when /.*Not$/.test i)
          disable = _.any nots, (e) -> kvm[e]()
          disable

      setupHistory kvm

      kvm['renderActions'] = -> renderActions(kvm)
      kvm['renderActions']()

      # make colored services and actions a little bit nicer
      $('.accordion-toggle:has(> .alert)').css 'padding', 0

      $(".status-btn-tooltip").tooltip()

    # History pane
    setupHistory = (kvm) ->
      historyDatetimeFormat = "dd.MM.yyyy HH:mm:ss"
      refreshHistory = ->
        $.getJSON "/caseHistory/#{kvm.id()}", (res) ->
          kvm['historyItems'].removeAll()
          for i in res
            if i[2].aeinterlocutors?
              i[2].aeinterlocutors =
                _.map(i[2].aeinterlocutors, utils.internalToDisplayed).
                  join(", ")
            kvm['historyItems'].push
              datetime: new Date(i[0]).toString historyDatetimeFormat
              who: i[1]
              json: i[2]
      kvm['refreshHistory'] = refreshHistory
      kvm['contact_phone1']?.subscribe refreshHistory

    # Case comments/chat
    setupCommentsHandler = (kvm) ->
      legId = "Case:#{kvm.id()}"
      if window.location.protocol == "https:"
        chatUrl = "wss://#{location.hostname}:#{location.port}/chat/#{legId}"
      else
        chatUrl = "ws://#{location.hostname}:#{location.port}/chat/#{legId}"

      chatNotify = (message, className) ->
        $.notify message, {className: className || 'info', autoHide: false}

      brDict = utils.newModelDict "BusinessRole"

      chatWs = new WS chatUrl
      chatWs.onmessage = (raw) ->
        msg = JSON.parse raw.data
        who = msg.user || msg.joined || msg.left
        if who.id == global.user.id
          return
        if who.id
          $.getJSON "/_/Usermeta/#{who.id}", (um) ->
            note = "Оператор #{um.login}"
            if msg.msg
              note += " оставил сообщение: #{msg.msg}"
              chatNotify note
            else
              if um.realName
                note += " (#{um.realName})"
              if um.workPhoneSuffix
                note += ", доб. #{um.workPhoneSuffix}"
              note += ", IP #{who.ip}"
              if um.businessRole
                note += " с ролью #{brDict.getLab(um.businessRole)}"
              if msg.joined
                note += " вошёл в кейс"
                chatNotify note, "error"
              if msg.left
                note += " вышел с кейса"
                chatNotify note, "success"

      $("#case-comments-b").on 'click', ->
        i = $("#case-comments-i")
        return if _.isEmpty i.val()
        chatWs.send i.val()
        $.ajax
          type: "POST"
          url: "/_/CaseComment"
          data: JSON.stringify {caseId: parseInt(kvm.id()), comment: i.val()}
          dataType: "json"
          success: -> kvm['refreshHistory']?()
        i.val("")

    # Manually re-render a list of case actions
    #
    # TODO Implement this as a read trigger for Case.actions EF with
    # WS subscription to action list updates
    renderActions = (kvm) ->
      caseId = kvm.id()
      refCounter = 0

      mkSubname = -> "case-#{caseId}-actions-view-#{refCounter++}"
      subclass = "case-#{caseId}-actions-views"

      # Top-level container for action elements
      cont = $("#case-actions-list")

      # TODO Add garbage collection
      # $(".#{subclass}").each((i, e) ->
      #   main.cleanupKVM global.viewsWare[e.id].knockVM)
      cont.children().remove()
      cont.spin('large')

      # Pick reference template
      tpl = flds.find("#actions-reference-template").html()

      # Flush old actionsList
      if kvm['actionsList']?
        kvm['actionsList'].removeAll()

      $.getJSON "/backoffice/caseActions/#{caseId}", (aids) ->
        for aid in aids
          # Generate reference container
          view = mkSubname()
          box = Mustache.render tpl,
            refView: view
            refClass: subclass
          cont.append box
          avm = main.modelSetup("Action") view, {id: aid},
            slotsee: [view + "-link"]
            parent: kvm
          # Redirect to backoffice when an action result changes
          avm["resultSync"]?.subscribe (nv) ->
            if !nv
              window.location.hash = "back"
          # There's no guarantee who renders first (services or
          # actions), try to set up an observable from here
          if not kvm['actionsList']?
            kvm['actionsList'] = ko.observableArray()
          kvm['actionsList'].push avm
          if avm["type"]() == global.idents("ActionType").accident && avm["myAction"]()
            if global.CTIPanel
              global.CTIPanel.instaDial kvm["contact_phone1"]()
              window.alert "Внимание: кейс от системы e-call, \
                производится набор номера клиента, возьмите трубку"
          # Disable action results if any of required case fields is
          # not set
          do (avm) ->
            avm.resultDisabled kvm['hasMissingRequireds']()
            kvm['hasMissingRequireds'].subscribe (dis) ->
              avm.resultDisabled?(dis)
        cont.spin false
      kvm['refreshHistory']?()

    # Top-level wrapper for storeService
    addService = (name) ->
      kvm = global.viewsWare["case-form"].knockVM
      modelArg = "ctr:#{kvm.program()}"
      mu.addReference kvm,
        'services',
        {modelName : name, options:
          newStyle: true
          parentField: 'parentId'
          modelArg: modelArg
          hooks: ['*']},
        (k) ->
          e = $('#' + k['view'])
          e.parent().prev()[0]?.scrollIntoView()
          e.find('input')[0]?.focus()
          # make colored service a little bit nicer even if it is just created
          $('.accordion-toggle:has(> .alert)').css 'padding', 0
          $(".status-btn-tooltip").tooltip()
          $("##{k['view']}-head").collapse 'show'

    utils.build_global_fn 'addService', ['screens/case']


    removeCaseMain = ->
      $("body").off "change.input"
      $('.navbar').css "-webkit-transform", ""


    { constructor       : setupCaseMain
    , destructor        : removeCaseMain
    , template          : tpl
    , addService        : addService
    }
