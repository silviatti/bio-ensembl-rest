module EnsemblRest 

  ## start HTTP database connection ##

  def self.connect_db 
    $SERVER = URI.parse 'http://beta.rest.ensembl.org'
    $HTTP_CONNECTION = Net::HTTP.new($SERVER.host, $SERVER.port)
  end


  ## parse options stuff ##
  # FIXME: refactor this crap
  def self.parse_options(opts, mod) # :nodoc:
    parsed_opts = {}
    opts.each {|k, v| parsed_opts[k.to_s] = v}

    parse_format parsed_opts
    case mod
    when 'sequence'
      parse_expand parsed_opts
      parse_multiseq parsed_opts
      parse_coords parsed_opts
    when 'compara'
      parse_aligned parsed_opts
      parse_species parsed_opts
      parse_taxon parsed_opts
      parse_condensed parsed_opts
    when 'crossreference'
      parse_all_levels parsed_opts
    when 'lookup'
      parse_full parsed_opts
    when 'ontologies'
      parse_zero_distance parsed_opts
      parse_closest_term parsed_opts
    end
    parsed_opts
  end

  ## common
  def self.parse_format(opts) # :nodoc:
    supported_formats = {
      'text' => 'text/plain',
      'fasta' => 'text/x-fasta',
      'gff3' => 'ext/x-gff3',
      'json' => 'application/json',
      'msgpack' => 'application/x-msgpack',
      'nh' => 'text/x-nh'
      'seqxml' => 'text/x-seqxml+xml', 
      'sereal' => 'application/x-sereal',
      'phyloxml' => 'text/x-phyloxml+xml',
      'xml' => 'text/xml',
      'yaml' => 'text/x-yaml'
    }
    if opts['format']
      if supported_formats[opts['format']]
        opts['content-type'] = supported_formats[opts['format']]
      else
        opts['content-type'] = opts['format']
      end
      opts.delete 'format'
    end
    opts
  end

  ## sequence
  def self.parse_expand(opts) # :nodoc:
    if opts['expand_down'] 
      opts['expand_3prime'] = opts['expand_down'] 
      opts.delete 'expand_down'
    end
    if opts['expand_up'] 
      opts['expand_5prime'] = opts['expand_up'] 
      opts.delete 'expand_up'
    end
  end

  def self.parse_multiseq(opts) # :nodoc:
    if opts['multiseq'] 
      opts['multiple_sequences'] = opts['multiseq'] ? '1' : '0'
      opts.delete 'multiseq'
    end
  end

  def self.parse_coords(opts) # :nodoc:
    if opts['coords']
      opts['coord_system'] = opts['coords']
      opts.delete 'coords'
    end
  end

  ## comparative
  def self.parse_aligned(opts) # :nodoc:
    if opts['aligned']
      opts['aligned'] = opts['aligned'] ? '1' : '0'
      opts.delete 'aligned'
    end
  end

  def self.parse_species(opts) # :nodoc:
    if opts['species']
      opts['target-species'] = opts['species']
      opts.delete 'species'
    end
  end

  def self.parse_taxon(opts) # :nodoc:
    if opts['taxon']
      opts['target_taxon'] = opts['taxon']
      opts.delete 'taxon'
    end
  end

  def self.parse_condensed(opts) # :nodoc:
    if opts['condensed']
      opts['format'] = 'condensed'
      opts.delete 'condensed'
    end
  end

  ## crossreference
  def self.parse_all_levels(opts) # :nodoc:
    if opts['all_levels']
      opts['all_levels'] = opts['all_levels'] ? '1' : '0'
    end
  end

  ## lookup
  def self.parse_full(opts) # :nodoc:
    if opts['full']
      opts['format'] = 'full'
      opts.delete 'full'
    end    
  end

  ## ontologies

  def self.parse_closest_term(opts) # :nodoc:
    if opts['closest_term']
      opts['closest_term'] = opts['closest_term'] ? '1' : '0'
    end
  end

    def self.parse_zero_distance(opts) # :nodoc:
    if opts['zero_distance']
      opts['zero_distance'] = opts['zero_distance'] ? '1' : '0'
    end
  end


  ## HTTP request stuff ##

  def self.build_path(home, opts) # :nodoc:
    path = home + '?'
    opts.each { |k,v| path << "#{k}=#{v};"  if k != 'content-type' }
    path[-1] = '' if not opts
    URI::encode path
  end

  def self.fetch_data(path, opts, mod) # :nodoc:
    # what we should set as content-type in the header
    # to keep ensembl happy when the the user does not
    # use the format parameter to set the return type
    default_types = {
      'sequence' => 'text/plain',
      'compara' => 'text/xml',
      'crossreference' => 'text/plain',
      'features' => 'text/plain',
      'information' => 'text/plain',
      'lookup' => 'application/json',
      'mapping' => 'application/json',
      'ontologies' => 'application/json',
      'taxonomy' => 'application/json',
      'variation' => 'application/json'
    }
    request = Net::HTTP::Get.new path
    request.content_type = opts['content-type'] || default_types[mod]
    response = $HTTP_CONNECTION.request request
    return check_response response
  end

  def self.check_response(response) # :nodoc:
    case response.code 
    when '200'
      return response.body
    when '400'
      raise 'Bad request: ' + response.body
    when '404' 
      raise 'Not Found'
    when '415'
      raise 'Unsupported Media Type'
    when '429' 
      raise 'Too many requests'
    when '503'
      raise 'Service Unavailable'
    else
      raise "Bad response code: #{response.code}"
    end
  end


end
