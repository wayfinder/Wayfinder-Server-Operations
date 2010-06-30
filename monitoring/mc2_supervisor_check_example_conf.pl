# This is an example config
#
# Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#     * Neither the name of the Vodafone Group Services Ltd nor the names of
#     its contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
%limits = (
   'leaders' => {
      'MM0' => '!=1', 'MM1' => '!=1',
      'SM0' => '!=1', 'SM1' => '!=1',
      'RM0' => '!=1', 'RM1' => '!=1',
      'UM0' => '!=1', 'UM1' => '!=1',
      'IM0' => '!=1', 'IM1' => '!=1',
      'GM0' => '!=1',
      'XM0' => '!=1',
      'EM0' => '!=1',
      'TIM0' => '!=1',
   },
   'module_count' => {
      'MM0' => '<20', 'MM1' => '<20',
      'SM0' => '<20', 'SM1' => '<20',
      'RM0' => '<20', 'RM1' => '<20',
      'UM0' => '<2', 'UM1' => '<2',
      'IM0' => '<2', 'IM1' => '<2',
      'GM0' => '<20',
      'XM0' => '<6',
      'EM0' => '<20',
      'TIM0' => '<20',
   },
   'queue_length' => {
      'MM0' => '>20', 'MM1' => '>20',
      'SM0' => '>20', 'SM1' => '>20',
      'RM0' => '>20', 'RM1' => '>20',
      'UM0' => '>20', 'UM1' => '>20',
      'IM0' => '>20', 'IM1' => '>20',
      'GM0' => '>20',
      'XM0' => '>20',
      'EM0' => '>20',
      'TIM0' => '>20',
    },
   'load_one' => {
      'MM0' => '>2', 'MM1' => '>2',
      'SM0' => '>15', 'SM1' => '>15', # the "search within a country feature" causes rather high loads for a very short time
      'RM0' => '>2', 'RM1' => '>2',
      'UM0' => '>2', 'UM1' => '>2',
      'IM0' => '>1.5', 'IM1' => '>1.5',
      'GM0' => '>2',
      'XM0' => '>3',
      'EM0' => '>2',
      'TIM0' => '>2',
    },
   'load_five' => {
      'MM0' => '>1.5', 'MM1' => '>1.5',
      'SM0' => '>10', 'SM1' => '>10', # see above
      'RM0' => '>1.5', 'RM1' => '>1.5',
      'UM0' => '>1.5', 'UM1' => '>1.5',
      'IM0' => '>1.0', 'IM1' => '>1.0',
      'GM0' => '>1.5',
      'XM0' => '>2.0',
      'EM0' => '>1.5',
      'TIM0' => '>1.5',
    },
   'load_fifteen' => {
      'MM0' => '>1', 'MM1' => '>1',
      'SM0' => '>5', 'SM1' => '>5', # see above
      'RM0' => '>1', 'RM1' => '>1',
      'UM0' => '>1.0', 'UM1' => '>1.0',
      'IM0' => '>0.5', 'IM1' => '>0.5',
      'GM0' => '>1',
      'XM0' => '>1.5',
      'EM0' => '>1',
      'TIM0' => '>1',
    },
   'process_time' => {
      'MM0' => '>150', 'MM1' => '>150',
      'SM0' => '>75',  'SM1' => '>75',
      'RM0' => '>400', 'RM1' => '>400',
      'UM0' => '>200', 'UM1' => '>200',
      'IM0' => '>80',  'IM1' => '>80',
      'GM0' => '>400',
      'XM0' => '>1500',
      'EM0' => '>100',
      'TIM0' => '>200',
    },
   'avg_queue_length' => {
      'MM0' => '>3', 'MM1' => '>3',
      'SM0' => '>3', 'SM1' => '>3',
      'RM0' => '>3', 'RM1' => '>3',
      'UM0' => '>3', 'UM1' => '>3',
      'IM0' => '>3', 'IM1' => '>3',
      'GM0' => '>3',
      'XM0' => '>3',
      'EM0' => '>3',
      'TIM0' => '>3',
    },
   'avg_load_one' => {
      'MM0' => '>1.5', 'MM1' => '>1.5',
      'SM0' => '>1.5', 'SM1' => '>1.5',
      'RM0' => '>1.5', 'RM1' => '>1.5',
      'UM0' => '>1.5', 'UM1' => '>1.5',
      'IM0' => '>1.5', 'IM1' => '>1.5',
      'GM0' => '>1.5',
      'XM0' => '>1.5',
      'EM0' => '>1.5',
      'TIM0' => '>1.5',
    },
   'avg_load_five' => {
      'MM0' => '>1.0', 'MM1' => '>1.0',
      'SM0' => '>1.0', 'SM1' => '>1.0',
      'RM0' => '>1.0', 'RM1' => '>1.0',
      'UM0' => '>1.0', 'UM1' => '>1.0',
      'IM0' => '>1.0', 'IM1' => '>1.0',
      'GM0' => '>1.0',
      'XM0' => '>1.0',
      'EM0' => '>1.0',
      'TIM0' => '>1.0',
    },
   'avg_load_fifteen' => {
      'MM0' => '>0.5',  'MM1' => '>0.5',
      'SM0' => '>0.5',  'SM1' => '>0.5',
      'RM0' => '>0.5',  'RM1' => '>0.5',
      'UM0' => '>1.75', 'UM1' => '>0.75',
      'IM0' => '>0.5',  'IM1' => '>0.5',
      'GM0' => '>0.5',
      'XM0' => '>0.5',
      'EM0' => '>0.5',
      'TIM0' => '>0.5',
    },
   'avg_process_time' => {
      'MM0' => '>80',  'MM1' => '>80',
      'SM0' => '>30',  'SM1' => '>30',
      'RM0' => '>200', 'RM1' => '>200',
      'UM0' => '>100', 'UM1' => '>100',
      'IM0' => '>60',  'IM1' => '>60',
      'GM0' => '>250',
      'XM0' => '>800',
      'EM0' => '>500',
      'TIM0' => '>100',
    },
);
