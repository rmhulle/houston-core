class @AllTicketsView extends @TicketsView
  template: HandlebarsTemplates['tickets/index']

  initialize: ->
    super
    @allTickets = @tickets
    $('#tickets_filter')
      .focus()
      .keyup _.bind(@filterTickets, @)

  render: ->
    @$el.find('tbody').remove()
    
    @offset = 0
    html = @template
      tickets: (ticket.toJSON() for ticket in @tickets.slice(0, 50))
    @$el.append(html)
    @$el.find('.ticket').pseudoHover()

  showTicketModal: (number)->
    ticketNumbers: @tickets.pluck('number')

  filterTickets: (e)->
    search = $(e.target).val()
    unless @lastSearch is search
      @lastSearch = search
      @tickets = if search then @allTickets.search(search) else @allTickets
      @render()

