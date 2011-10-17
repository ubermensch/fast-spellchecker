
# Read a large list of words (such as /usr/share/dict/words) into memory, and then read
# words from stdin which prints the best spelling suggestion or "No Suggestion" if
# it can't find any suggestions. It should print "> " as a prompt before reading every word,
# and loop until killed.
#
# The spellchecker should be faster than O(n) where n is the dictionary length.
# Basically, your solution cannot loop over the dictionary every time you spellcheck a word.
#
# Example results:
#
#  > aappliiii
#
#    apple
#
#  > tomaaaatttooo
#
#    tomato
#
#  > cabage
#
#    No Suggestion
#
# The kind of spelling mistakes it should be able to correct:
#
#  Casing errors ("CaT" -> "cat")
#
#  Letter repetition ("ddesskk" -> "desk")
#
#  Incorrect vowels ("ewokan" -> "awoken")
#
#  Any combination of the above ("InnSpERataen" -> "inspiration")
#
# The corrections your program makes does not necessarily need to match
# the ones given above. If there are multiple possible corrections,
# you can choose which one to use. As long as it's an English word and
# it's only using the above rules for spelling corrections.
#
#
#
# Once you have finished a program to correct spelling mistakes,
# write one that can generates misspelled words using the above criteria.
# Pass the output to the spell checker and make sure there are no occurrences
# of "No Suggestion" in the output.


module SpellChecker

  # Encoding a dictionary of words as an n-ary tree.
  # There are all sorts of optimizations that could be made here, such as alphabetically ordering
  # the nodes at each level. Since there are only 26 possible children for each individual node,
  # finding a child is O(1) bound anyway.
  class DictTree

    def initialize(words_array)
      @root = DictTreeNode.new('root')
      puts " [DictTree initialize()] Building dictionary lookup tree.."
      build_tree(words_array)
      puts " [DictTree initialize()] ...done. #{words_array.size} words included in lookup tree."
    end


    def is_word?(word)
       return has_word(@root, word, 0)
    end

    private

    def build_tree(words_array)
       words_array.each do |word|
         place_word(@root, word, 0)
       end
    end

    def has_word(node, word, letter_index)
      return true if letter_index == word.size

      if !node.has_child(word[letter_index])
        return false
      end
      return has_word(node.get_child(word[letter_index]), word, letter_index + 1)

    end

    def place_word(node, word, letter_index)
       # base case : we've run out of letters
       if letter_index == word.size
         # puts "  > placed '#{word}'"
         return
       end

       # recursive case - traverse the node tree for each letter, appending the
       # node if it doesn't exist
       if !node.has_child(word[letter_index])
         node.add_child(word[letter_index])
       end
       return place_word(node.get_child(word[letter_index]), word, letter_index + 1)
    end


  end

  class DictTreeNode

    attr_reader :node_text
    attr_reader :children

    def initialize(node_text)
       @node_text = node_text
       @children = []
    end

    def add_child(node_text)
      @children << DictTreeNode.new(node_text)
    end

    def has_child(node_text)
      @children.each do |child|
        return true if child.node_text === node_text
      end
      false
    end

    def get_child(node_text)
      @children.each do |child|
        return child if child.node_text === node_text
      end
      nil
    end

  end


  class FastSpellChecker

      # Expects a dictionary file of all the canonical words (and their spellings)
      # that the spellchecker uses.
      def initialize(path_to_dict = nil)
        raise ArgumentError("Expected file system path to dictionary file") if path_to_dict.nil?
        raise ArgumentError("Given file #{path_to_dict} doesn't exist") if !File::exists? path_to_dict

        @dict_path = path_to_dict

        # Initialize the dictionary
        # @words_array = IO.readlines(@dict_path).sort!.each { |word| word.strip!; word.downcase! }
        @words_array = IO.readlines(@dict_path).sort.collect { |word| word.strip.downcase }

        @lookup_dictionary = DictTree.new(@words_array)
      end



      # Given a misspelled word, offers a possible correction for it. If it doesn't have one,
      # returns 'No Suggestion'
      def get_suggestion(word)

        suggestion = nil

        # We have 3 strategies - case, letter repetition and incorrect vowels
        # Can use Procs for these, put them in an array and then use combination()
        # function
        case_correction = Proc.new do |w_array|
          w_array.collect { |curr_w| curr_w.downcase }
        end

        letter_repetition = Proc.new do |w_array|
          # for each word given in the w_array, we need to
          # remove the repeated characters
          new_array = w_array.dup
          #w_array.each do |curr_w|
          #
          #end
        end

        incorrect_vowels = Proc.new do |w_array|
          new_array = w_array.dup
          vowels = ['a', 'e', 'i', 'o', 'u']
          w_array.each do |curr_w|
            for char_i in 0...curr_w.length
              char = curr_w[char_i]
              if vowels.include? char
                applicable_vowels = vowels.dup
                applicable_vowels.delete(char)
                applicable_vowels.each do |vowel|
                  added_word = curr_w.dup
                  added_word[char_i] = vowel
                  new_array << added_word
                end
              end
            end
          end
          new_array
        end

        # We put our correction strategies into an array and then run through all permutations
        # of them. Each strategy's output (an array of potentially correct words created by the correction applied)
        # is the input to the next strategy in the chain. We short-circuit the whole thing when we find
        # the first correct word
        strategies = [ case_correction, incorrect_vowels ]
        strategies.permutation(2).to_a.each do |perm|
          w_array = [ word ]
          perm.each do |strategy|
            w_array = strategy.call(w_array)
            w_array.each do |possible_word|
              if @lookup_dictionary.is_word? possible_word
                suggestion = possible_word
                break
              end
            end
            break unless suggestion.nil?
          end
          break unless suggestion.nil?
        end

        suggestion = 'No Suggestion' if suggestion.nil?
        suggestion
      end



  end




  class TypoGenerator

      # Expects a dictionary file of all the canonical words (and their spellings)
      def initialize(path_to_dict = nil)
        raise ArgumentError("Expected file system path to dictionary file") if path_to_dict.nil?
        raise ArgumentError("Given file #{path_to_dict} doesn't exist") if !File::exists? path_to_dict

        @dict_path = path_to_dict

        # Initialize the dictionary
        @words_array = IO.readlines(@dict_path).sort!

      end

  end

end

fsc = SpellChecker::FastSpellChecker.new('/usr/share/dict/words')
while true
  print " > "
  input_word = gets
  suggestion = fsc.get_suggestion(input_word.strip)
  puts suggestion

end
