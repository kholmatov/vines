# encoding: UTF-8

module Vines
  class Contact
    include Comparable

    attr_accessor :name, :subscription, :ask, :groups
    attr_reader :jid

    def initialize(args={})
      @jid = JID.new(args[:jid]).bare
      raise ArgumentError, 'invalid jid' unless @jid.node && !@jid.domain.empty?
      @name = args[:name]
      @subscription = args[:subscription] || 'none'
      @ask = args[:ask]
      @groups = args[:groups] || []
    end

    def <=>(contact)
      self.jid.to_s <=> contact.jid.to_s
    end

    def eql?(contact)
      contact.is_a?(Contact) && self == contact
    end

    def hash
      jid.to_s.hash
    end

    def update_from(contact)
      @name = contact.name
      @subscription = contact.subscription
      @ask = contact.ask
      @groups = contact.groups.clone
    end

    # Returns true if this contact is in a state that allows the user
    # to subscribe to their presence updates.
    def can_subscribe?
      @ask == 'subscribe' && %w[none from].include?(@subscription)
    end

    def subscribe_to
      @subscription = (@subscription == 'none') ? 'to' : 'both'
      @ask = nil
    end

    def unsubscribe_to
      @subscription = (@subscription == 'both') ? 'from' : 'none'
    end

    def subscribe_from
      @subscription = (@subscription == 'none') ? 'from' : 'both'
      @ask = nil
    end

    def unsubscribe_from
      @subscription = (@subscription == 'both') ? 'to' : 'none'
    end

    # Returns true if the user is subscribed to this contact's
    # presence updates.
    def subscribed_to?
      %w[to both].include?(@subscription)
    end

    # Returns true if the user has a presence subscription from
    # this contact. The contact is subscribed to this user's presence.
    def subscribed_from?
      %w[from both].include?(@subscription)
    end

    # Returns a hash of this contact's attributes suitable for persisting in
    # a document store.
    def to_h
      {
        'name' => @name,
        'subscription' => @subscription,
        'ask' => @ask,
        'groups' => @groups.sort!
      }
    end

    # Returns this contact as an xmpp <item> element.
    def to_roster_xml
      doc = Nokogiri::XML::Document.new
      doc.create_element('item') do |el|
        el['ask'] = @ask unless @ask.nil? || @ask.empty?
        el['jid'] = @jid.bare.to_s
        el['name'] = @name unless @name.nil? || @name.empty?
        el['subscription'] = @subscription
        @groups.sort!.each do |group|
          el << doc.create_element('group', group)
        end
      end
    end
  end
end
